// The Swift Programming Language
// https://docs.swift.org/swift-book

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
    public init(
        client: ClientTransport,
        conversation: Conversation? = nil,
        retryAdviser: RetryAdviser = .shared,
        logger: Logger? = nil
    ) {
        self.client = client
        self.lockedConversation = .init(conversation)
        self.retryAdviser = retryAdviser
        self.logger = logger ?? Logger.disabled
    }
}

public extension GPTSession {
    /// The current conversation history.
    ///
    /// This property provides access to the conversation history maintained by the session.
    /// It is thread-safe and can be accessed concurrently.
    ///
    /// The Conversation will be updated after the whole request is complete.
    var conversation: Conversation? {
        lockedConversation.withLock { $0 }
    }
}

public extension GPTSession {
    /// Streams partial results from the LLM as they become available.
    ///
    /// The returned asynchronous sequence yields ``ModelStreamResponse`` events, allowing you to process the response incrementally.
    ///
    /// - Parameters:
    ///   - prompt: The prompt to send. The `stream` property must be `true`.
    ///   - model: The specific model and provider to use for the request.
    /// - Returns: An `AnyAsyncSequence` of ``ModelStreamResponse`` events.
    /// - Throws: A ``RuntimeError`` or other transport-level error if the request fails.
    func stream(
        _ prompt: Prompt,
        model: LLMModelReference,
        serviceContext: ServiceContext = .current ?? .topLevel
    ) async throws -> AnyAsyncSequence<ModelStreamResponse> {
        assert(prompt.stream == true, "The prompt perfer do use stream.")

        // Build Conversation
        let history = conversation ?? Conversation()

        let provider = model.provider
        self.logger.debug("[*] provider: \(provider)")
        
        let stream: AnyAsyncSequence<ModelStreamResponse> = try await provider.type.provider.generate(
            client: client,
            provider: model.provider,
            model: model.model,
            prompt,
            conversation: history,
            logger: logger,
            serviceContext: serviceContext
        )

        return stream.map { [history] response in
            if case .completed(let event) = response {
                lockedConversation.withLock {
                    $0 = history
                    $0?.lastReference = event.data.id |> { .init(name: provider.name, provider: provider.type, id: $0) }
                    $0?.items.append(contentsOf: prompt.inputs.map { .input($0) })
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
    ///   - timeout: The timeout of the request include fetch body.
    /// - Returns: A ``ModelResponse`` containing the full response from the LLM.
    /// - Throws: A ``RuntimeError`` or other transport-level error if the request fails.
    func generate(
        _ prompt: Prompt,
        model: LLMModelReference,
        timeout: TimeInterval? = nil,
        serviceContext: ServiceContext = .current ?? .topLevel
    ) async throws -> ModelResponse {
        assert(prompt.stream == false, "The prompt perfer do not use stream.")

        var history = conversation ?? Conversation()

        let provider = model.provider
        self.logger.debug("[*] provider: \(provider)")
        
        let response: ModelResponse = if let timeout {
            try await Task.timeout(for: .seconds(timeout)) { [history] in
                try await provider.type.provider.generate(
                    client: client,
                    provider: model.provider,
                    model: model.model,
                    prompt,
                    conversation: history,
                    logger: logger,
                    serviceContext: serviceContext
                )
            }
        } else {
            try await provider.type.provider.generate(
                client: client,
                provider: model.provider,
                model: model.model,
                prompt,
                conversation: history,
                logger: logger,
                serviceContext: serviceContext
            )
        }

        history.lastReference = response.id |> { .init(name: provider.name, provider: provider.type, id: $0) }
        history.items.append(contentsOf: prompt.inputs.map { .input($0) })
        history.items.append(contentsOf: response.items.map { .generated($0) })

        lockedConversation.withLock { [history] in $0 = history }
        return response
    }
}
