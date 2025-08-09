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

    public func send(
        _ prompt: Prompt,
        model: LLMModelReference
    ) async throws -> AnyAsyncSequence<ModelStreamResponse> {
        assert(prompt.stream == true, "The prompt perfer do not use stream.")

        let provider = model.provider.type.provider
        
        let stream = try await provider.send(client: client, provider: model.provider, model: model.model, prompt, logger: logger)
        
        return stream
    }
    
    
    
    /// Send LLM Requests with Guaranteed Retries Using Mutiple Models
    ///
    ///
    public func send(
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
                    continue
                }
                
                let response =  try await self.send(prompt, model: cur)
                
                retryAdviser.cleanCache(model: cur)
                
                return response
            } catch {
                logger.notice("[*] GPTSession send prompt failed. Prompt: `\(prompt)` Model: `\(cur)`. Error: \(error)")
                ctx.errors.append(error)
                
                if !retryAdviser.retry(ctx, error: error) {
                    model = iter.next()
                    continue
                }
                
                do {
                    try await Task.sleep(nanoseconds: 1_000_000 * 0)
                } catch {
                    logger.notice("[*] GPTSession retry failed when sleep. ignored.")
                }
            }
        } while model != nil
        
        throw RuntimeError.retryFailed(ctx.errors)
    }
    
}

extension HTTPFields {
    public var contentLength: Int? {
        guard let value = self[.contentLength] else {
            return nil
        }
        return Int(value)
    }

    public var contentType: String? {
        self[.contentType]
    }
}
