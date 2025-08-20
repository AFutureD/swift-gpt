// The Swift Programming Language
// https://docs.swift.org/swift-book

import HTTPTypes
import LazyKit
import NetworkKit
import OpenAPIRuntime
import SynchronizationKit
import Logging

public struct GPTSession: Sendable {
    let client: ClientTransport
    let retryAdviser: RetryAdviser
    
    let sessionID: LazyLockedValue<String?> = .init(nil)
    
    let logger: Logger
    
    public init(client: ClientTransport, retryAdviser: RetryAdviser = .shared, logger: Logger? = nil) {
        self.client = client
        self.retryAdviser = retryAdviser
        self.logger = logger ?? Logger.disabled
    }
}

extension GPTSession {
    
    public func stream(
        _ prompt: Prompt,
        model: LLMModelReference
    ) async throws -> AnyAsyncSequence<ModelStreamResponse> {
        assert(prompt.stream == true, "The prompt perfer do use stream.")
        
        let provider = model.provider.type.provider
        
        let stream: AnyAsyncSequence<ModelStreamResponse> = try await provider.generate(client: client, provider: model.provider, model: model.model, prompt, logger: logger)
        
        return stream
    }
    
    public func generate(
        _ prompt: Prompt,
        model: LLMModelReference
    ) async throws -> ModelResponse {
        assert(prompt.stream == false, "The prompt perfer do not use stream.")
        
        let provider = model.provider.type.provider
        
        let response: ModelResponse = try await provider.generate(client: client, provider: model.provider, model: model.model, prompt, logger: logger)
        
        return response
    }
}


extension GPTSession {
    /// Send LLM Requests with Guaranteed Retries Using Mutiple Models
    ///
    ///
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
                ctx.model = model
                
                if retryAdviser.skip(ctx) {
                    ctx.errors.append(RuntimeError.skipByRetryAdvice)
                    model = iter.next()
                    logger.notice("[*] GPTSession skip modal(\(cur)). Reason: skiped by RetryAdviser.")
                    continue
                }
                
                let response: AnyAsyncSequence<ModelStreamResponse> =  try await self.stream(prompt, model: cur)
                
                retryAdviser.cleanCache(model: cur)
                
                return response
            } catch {
                logger.error("[*] GPTSession send prompt failed. Model: `\(cur)` Prompt: `\(prompt)` Error: \(error)")
                ctx.errors.append(error)
                
                guard let retry = retryAdviser.retry(ctx, error: error) else {
                    model = iter.next()
                    logger.notice("[*] GPTSession retry failed when sleep. ignored.")
                    continue
                }
                
                logger.notice("[*] GPTSession retry with same model(\(model?.description ?? "nil"))")
                do {
                    try await Task.sleep(nanoseconds: retry)
                } catch {
                    logger.notice("[*] GPTSession retry failed when sleep. ignored.")
                }
            }
        } while model != nil
        
        throw RuntimeError.retryFailed(ctx.errors)
    }
    
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
                ctx.model = model
                
                if retryAdviser.skip(ctx) {
                    ctx.errors.append(RuntimeError.skipByRetryAdvice)
                    model = iter.next()
                    logger.notice("[*] GPTSession skip modal(\(cur)). Reason: skiped by RetryAdviser.")
                    continue
                }
                
                let response: ModelResponse =  try await self.generate(prompt, model: cur)
                
                retryAdviser.cleanCache(model: cur)
                
                return response
            } catch {
                logger.error("[*] GPTSession send prompt failed. Model: `\(cur)` Prompt: `\(prompt)` Error: \(error)")
                ctx.errors.append(error)
                
                guard let retry = retryAdviser.retry(ctx, error: error) else {
                    model = iter.next()
                    logger.notice("[*] GPTSession retry failed when sleep. ignored.")
                    continue
                }
                
                logger.notice("[*] GPTSession retry with same model(\(model?.description ?? "nil"))")
                do {
                    try await Task.sleep(nanoseconds: retry)
                } catch {
                    logger.notice("[*] GPTSession retry failed when sleep. ignored.")
                }
            }
        } while model != nil
        
        throw RuntimeError.retryFailed(ctx.errors)
    }
}
