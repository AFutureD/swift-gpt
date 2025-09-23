// The Swift Programming Language
// https://docs.swift.org/swift-book

import HTTPTypes
import LazyKit
import NetworkKit
import OpenAPIRuntime
import SynchronizationKit
import Logging

/// The Session for interacting with LLMs.
///
/// A `GPTSession` is used to send prompts to LLM providers and receive responses.
/// It handles the underlying network requests, streaming, and retry logic.
public struct GPTSession: Sendable {
    let client: ClientTransport
    let retryAdviser: RetryAdviser
    
    let lockedConversation: LazyLockedValue<Conversation?>
    
    let logger: Logger
    
    /// Creates a new `GPTSession`.
    ///
    /// - Parameters:
    ///   - client: The `ClientTransport` to use for network requests.
    ///   - retryAdviser: The ``RetryAdviser`` to use for handling failures. Defaults to the shared instance.
    ///   - logger: The `Logger` to use for logging. Defaults to a disabled logger.
    public init(client: ClientTransport, conversation: Conversation? = nil, retryAdviser: RetryAdviser = .shared, logger: Logger? = nil) {
        self.client = client
        self.lockedConversation = .init(conversation)
        self.retryAdviser = retryAdviser
        self.logger = logger ?? Logger.disabled
    }
}

extension GPTSession {
    /// The current conversation history.
    ///
    /// This property provides access to the conversation history maintained by the session.
    /// It is thread-safe and can be accessed concurrently.
    ///
    /// The Conversation will be updated after the whole request is complete.
    public var conversation: Conversation? {
        lockedConversation.withLock { $0 }
    }
}


extension GPTSession {
    
    /// Streams partial results from the LLM as they become available.
    ///
    /// The returned asynchronous sequence yields ``ModelStreamResponse`` events, allowing you to process the response incrementally.
    ///
    /// - Parameters:
    ///   - prompt: The prompt to send. The `stream` property must be `true`.
    ///   - model: The specific model and provider to use for the request.
    /// - Returns: An `AnyAsyncSequence` of ``ModelStreamResponse`` events.
    /// - Throws: A ``RuntimeError`` or other transport-level error if the request fails.
    public func stream(
        _ prompt: Prompt,
        model: LLMModelReference
    ) async throws -> AnyAsyncSequence<ModelStreamResponse> {
        assert(prompt.stream == true, "The prompt perfer do use stream.")

        // Build Conversation
        let history = conversation ?? Conversation()

        let provider = model.provider.type.provider
        let stream: AnyAsyncSequence<ModelStreamResponse> = try await provider.generate(client: client, provider: model.provider, model: model.model, prompt, conversation: history, logger: logger)
        
        return stream.map { [history] response in 
            if case .completed(let event) = response {
                lockedConversation.withLock { 
                    $0 = history
                    $0?.items.append(contentsOf: prompt.inputs.map { .input($0)})
                    $0?.items.append(contentsOf: event.data.items.map { .generated($0) })
                }
            }
            return response
        }.eraseToAnyAsyncSequence()
    }
    
    /// Generates a complete, non-streaming response from the LLM.
    ///
    /// This method waits for the full response from the LLM before returning.
    ///
    /// - Parameters:
    ///   - prompt: The prompt to send. The `stream` property must be `false`.
    ///   - model: The specific model and provider to use for the request.
    /// - Returns: A ``ModelResponse`` containing the full response from the LLM.
    /// - Throws: A ``RuntimeError`` or other transport-level error if the request fails.
    public func generate(
        _ prompt: Prompt,
        model: LLMModelReference
    ) async throws -> ModelResponse {
        assert(prompt.stream == false, "The prompt perfer do not use stream.")

        var history = conversation ?? Conversation()
        
        let provider = model.provider.type.provider
        let response: ModelResponse = try await provider.generate(client: client, provider: model.provider, model: model.model, prompt, conversation: history, logger: logger)
        
        history.items.append(contentsOf: prompt.inputs.map { .input($0)})
        history.items.append(contentsOf: response.items.map { .generated($0) })
        
        lockedConversation.withLock { [history] in $0 = history }
        return response
    }
}


extension GPTSession {
    /// Streams partial results from a qualified model, with automatic retries and fallbacks.
    ///
    /// This method iterates through the models in the ``LLMQualifiedModel``, attempting the request according to the ``RetryAdviser``'s strategy.
    ///
    /// - Parameters:
    ///   - prompt: The prompt to send. The `stream` property must be `true`.
    ///   - model: A qualified model containing one or more models to try in sequence.
    /// - Returns: An `AnyAsyncSequence` of ``ModelStreamResponse`` events from the first successful model.
    /// - Throws: A ``RuntimeError`` if all models and retry attempts fail.
    public func stream(
        _ prompt: Prompt,
        model: LLMQualifiedModel
    ) async throws -> AnyAsyncSequence<ModelStreamResponse> {
        guard !model.models.isEmpty else {
            throw RuntimeError.emptyModelList
        }

        var iter = model.models.makeIterator()
        var model = iter.next()
        
        var ctx = RetryAdviser.Context()
        
        repeat {
            guard let cur = model else { break }
            
            do {
                ctx.current = model
                
                if retryAdviser.skip(ctx) {
                    ctx.append(RuntimeError.skipByRetryAdvice)
                    model = iter.next()
                    logger.notice("[*] GPTSession skip modal(\(cur)). Reason: skiped by RetryAdviser.")
                    continue
                }
                
                let response: AnyAsyncSequence<ModelStreamResponse> =  try await self.stream(prompt, model: cur)
                
                retryAdviser.cleanCache(model: cur)
                
                return response
            } catch {
                logger.error("[*] GPTSession send prompt failed. Model: `\(cur)` Prompt: `\(prompt)` Error: \(error)")
                ctx.append(error)
                
                guard let retry = retryAdviser.retry(ctx, error: error) else {
                    model = iter.next()
                    logger.notice("[*] GPTSession retry with next model: \(model?.description ?? "nil")")
                    continue
                }
                
                logger.notice("[*] GPTSession retry with same model(\(model?.description ?? "nil"))")
                do {
                    try await Task.sleep(nanoseconds: retry)
                } catch {
                    logger.notice("[*] GPTSession retry failed when sleep. ignored. Error: \(error)")
                }
            }
        } while model != nil
        
        throw RuntimeError.retryFailed(ctx.errors)
    }
    
    /// Generates a complete, non-streaming response from a qualified model, with automatic retries and fallbacks.
    ///
    /// This method iterates through the models in the ``LLMQualifiedModel``, attempting the request according to the ``RetryAdviser``'s strategy.
    ///
    /// - Parameters:
    ///   - prompt: The prompt to send. The `stream` property must be `false`.
    ///   - model: A qualified model containing one or more models to try in sequence.
    /// - Returns: A ``ModelResponse`` from the first successful model.
    /// - Throws: A ``RuntimeError`` if all models and retry attempts fail.
    public func generate(
        _ prompt: Prompt,
        model: LLMQualifiedModel
    ) async throws -> ModelResponse {
        guard !model.models.isEmpty else {
            throw RuntimeError.emptyModelList
        }
        
        var iter = model.models.makeIterator()
        var model = iter.next()
        
        var ctx = RetryAdviser.Context()
        
        repeat {
            guard let cur = model else { break }
            
            do {
                ctx.current = cur
                
                if retryAdviser.skip(ctx) {
                    ctx.append(RuntimeError.skipByRetryAdvice)
                    model = iter.next()
                    logger.notice("[*] GPTSession skip modal(\(cur)). Reason: skiped by RetryAdviser.")
                    continue
                }
                
                let response: ModelResponse =  try await self.generate(prompt, model: cur)
                
                retryAdviser.cleanCache(model: cur)
                
                return response
            } catch {
                logger.error("[*] GPTSession send prompt failed. Model: `\(cur)` Prompt: `\(prompt)` Error: \(error)")
                ctx.append(error)
                
                guard let retry = retryAdviser.retry(ctx, error: error) else {
                    model = iter.next()
                    logger.notice("[*] GPTSession retry with next model: \(model?.description ?? "nil")")
                    continue
                }
                
                logger.notice("[*] GPTSession retry with same model(\(model?.description ?? "nil"))")
                do {
                    try await Task.sleep(nanoseconds: retry)
                } catch {
                    logger.notice("[*] GPTSession retry failed when sleep. ignored. Error: \(error)")
                }
            }
        } while model != nil
        
        throw RuntimeError.retryFailed(ctx.errors)
    }
}
