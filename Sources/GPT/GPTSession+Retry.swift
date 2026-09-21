//
//  GPTSession+Retry.swift
//  swift-gpt
//
//  Created by Huanan on 2026/9/21.
//

import Foundation
import HTTPTypes
import LazyKit
import Logging
import NetworkKit
import OpenAPIRuntime
import ServiceContextModule
import Swiftic
import SynchronizationKit
import Tracing


public extension GPTSession {
    /// Streams partial results from a qualified model, with automatic retries and fallbacks.
    ///
    /// This method iterates through the models in the ``LLMQualifiedModel``, attempting the request according to the ``RetryAdviser``'s strategy.
    ///
    /// - Parameters:
    ///   - prompt: The prompt to send. The `stream` property must be `true`.
    ///   - model: A qualified model containing one or more models to try in sequence.
    /// - Returns: An `AnyAsyncSequence` of ``ModelStreamResponse`` events from the first successful model.
    /// - Throws: A ``RuntimeError`` if all models and retry attempts fail.
    func stream(
        _ prompt: Prompt,
        model: LLMQualifiedModel,
        serviceContext: ServiceContext = .current ?? .topLevel
    ) async throws -> AnyAsyncSequence<ModelStreamResponse> {
        let span = startSpan("GPT Session Generating", context: serviceContext)

        do {
            guard !model.models.isEmpty else {
                span.addEvent(.init(name: "Generate Failed", attributes: .init(["error": .string("emptyModelList")])))
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
                        let error = RuntimeError.skipByRetryAdvice
                        ctx.append(error)
                        model = iter.next()
                        logger.notice("[*] GPTSession skip modal(\(cur)). Reason: skiped by RetryAdviser.")
                        span.addEvent(.init(name: "SKip Provider", attributes: .init(["error": .string(error.description)])))
                        continue
                    }

                    let response: AnyAsyncSequence<ModelStreamResponse> = try await stream(prompt, model: cur, serviceContext: span.context)

                    retryAdviser.cleanCache(model: cur)

                    return response.map {
                        if case .completed = $0 {
                            span.end() // IMPORTANT
                        }
                        return $0
                    }.eraseToAnyAsyncSequence()
                } catch {
                    span.recordError(error)
                    logger.error("[*] GPTSession send prompt failed. Model: `\(cur)` Prompt: `\(prompt)` Error: \(error)")
                    ctx.append(error)

                    guard let retry = retryAdviser.retry(ctx, error: error) else {
                        model = iter.next()
                        logger.notice("[*] GPTSession retry with next model: \(model?.description ?? "nil")")
                        span.addEvent("Next Provider")
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
        } catch {
            span.setStatus(.init(code: .error))
            span.recordError(error)
            span.end() // IMPORTANT
            throw error
        }
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
    func generate(
        _ prompt: Prompt,
        model: LLMQualifiedModel,
        timeout: TimeInterval? = nil,
        serviceContext: ServiceContext = .current ?? .topLevel
    ) async throws -> ModelResponse {
        return try await withSpan("GPT Session Generating", context: serviceContext) { span in
            guard !model.models.isEmpty else {
                span.addEvent(.init(name: "Generate Failed", attributes: .init(["error": .string("emptyModelList")])))
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
                        let error = RuntimeError.skipByRetryAdvice
                        ctx.append(error)
                        model = iter.next()
                        logger.notice("[*] GPTSession skip modal(\(cur)). Reason: skiped by RetryAdviser.")
                        span.addEvent(.init(name: "SKip Provider", attributes: .init(["error": .string(error.description)])))
                        continue
                    }

                    let response: ModelResponse = try await generate(prompt, model: cur, timeout: timeout, serviceContext: span.context)

                    retryAdviser.cleanCache(model: cur)

                    return response
                } catch {
                    span.recordError(error)
                    logger.error("[*] GPTSession send prompt failed. Model: `\(cur)` Prompt: `\(prompt)` Error: \(error)")
                    ctx.append(error)

                    guard let retry = retryAdviser.retry(ctx, error: error) else {
                        model = iter.next()
                        logger.notice("[*] GPTSession retry with next model: \(model?.description ?? "nil")")
                        span.addEvent("Next Provider")
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

            span.setStatus(.init(code: .error))
            throw RuntimeError.retryFailed(ctx.errors)
        }
    }
}
