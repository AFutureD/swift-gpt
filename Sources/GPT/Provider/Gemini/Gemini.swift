import Atomics
import Foundation

import Gemini
import HTTPTypes
import LazyKit
import Logging
import NetworkKit
import OpenAPIRuntime
import ServiceContextModule
import Swiftic
import TraceKit
import Tracing

package struct AuthenticationMiddleware {
    /// The value for the `Authorization` header field.
    private let value: String

    /// Creates a new middleware.
    /// - Parameter value: The value for the `Authorization` header field.
    package init(apiKey value: String) { self.value = value }
}

extension AuthenticationMiddleware: ClientMiddleware {
    package func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID _: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var request = request
        // Adds the `Authorization` header field with the provided value.
        request.headerFields[HTTPField.Name("x-goog-api-key")!] = value
        return try await next(request, body, baseURL)
    }
}

struct GeminiProvider: LLMProvider {
    func generate(
        client: ClientTransport,
        provider: LLMProviderConfiguration,
        model: LLMModel,
        _ prompt: Prompt,
        conversation: Conversation,
        logger _: Logger,
        serviceContext: ServiceContext = .current ?? .topLevel
    ) async throws -> AnyAsyncSequence<ModelStreamResponse> {
        assert(prompt.stream == true, "The prompt perfer do not use stream.")

        let decoder = JSONDecoder()
        let encoder = JSONEncoder()

        return try await withSpan("GeminiProvider Generating", context: serviceContext) { span in
            span.attributes.set("stream", value: .bool(true))
            span.attributes.set("model", value: .string(model.name))
            span.attributes.set("provoder", value: .string(provider.description))
            span.attributes.set("conversation_id", value: .string(conversation.id ?? "nil"))

            let providerURL = try require(URL(string: provider.apiURL), error: RuntimeError.invalidApiURL(provider.apiURL))

            let body = Gemini.Components.Schemas.GenerateContentRequest(prompt, history: conversation)

            // Build Request
            let request = HTTPRequest(
                method: .post,
                scheme: nil,
                authority: nil,
                path: "/models/\(model.name):streamGenerateContent?alt=sse",
                headerFields: [
                    .contentType: "application/json",
                    .init("x-goog-api-key")!: provider.apiKey,
                ]
            )

            let bodyData = try encoder.encode(body)
            let (response, _responseBody) = try await client.send(request, body: .init(bodyData), baseURL: providerURL, operationID: UUID().uuidString)

            span.attributes.set("response.status.code", value: .init(integerLiteral: response.status.code))
            span.attributes.set("response.status.message", value: .string(response.status.description))

            guard response.status == .ok else {
                let e = try await _responseBody |> { try await String(collecting: $0, upTo: .max) }
                throw RuntimeError.httpError(response.status, e)
            }

            let contentType = response.headerFields.contentType
            try require(contentType?.starts(with: ServerSentEvent.MIME_String) ?? false, error: RuntimeError.reveiveUnsupportedContentTypeInResponse)

            let responseBody = try _responseBody ?? RuntimeError.emptyResponseBody

            return AsyncThrowingStream<ModelStreamResponse, Error> { continuation in
                let task = Task { @Sendable in
                    let stream = responseBody.map {
                        Data($0)
                    }.mapToServerSentEvert().map {
                        try decoder.decode(Gemini.Components.Schemas.GenerateContentResponse.self, from: Data($0.data.utf8))
                    }

                    let generationConext = GenerationConext(conversationID: conversation.id, provider: provider)

                    // The Main Loop
                    let innerSpan = startSpan("Receive Response", context: span.context)
                    do {
                        let initialed = ManagedAtomic<Bool>(false)

                        var responseID: String? = nil
                        var textContent: String? = nil

                        var usage: TokenUsage? = nil
                        var stop: GenerationStop? = nil
                        var error: GenerationError? = nil

                        for try await response in stream {
                            responseID = response.responseId

                            let initialed = initialed.exchange(true, ordering: .acquiring)
                            if !initialed {
                                continuation.yield(.create(.init(event: .create, data: ModelResponse(
                                    id: responseID,
                                    context: generationConext,
                                    model: model.name,
                                    items: [],
                                    usage: nil,
                                    stop: nil,
                                    error: nil
                                ))))
                            }

                            let candidate = response.candidates?.first
                            if let blockReason = response.promptFeedback?.value1.blockReason {
                                error = .init(code: String(blockReason.rawValue), message: nil)
                            }

                            if let usageMetadata = response.usageMetadata?.value1 {
                                usage = TokenUsage(
                                    input: Int(usageMetadata.promptTokenCount ?? 0),
                                    output: Int(usageMetadata.candidatesTokenCount ?? 0),
                                    total: Int(usageMetadata.totalTokenCount ?? 0)
                                )
                            }
                            guard let candidate, let part = candidate.content?.value1.parts?.first else {
                                break
                            }

                            if let finishReason = candidate.finishReason {
                                stop = GenerationStop(code: String(finishReason.rawValue), message: candidate.finishMessage)
                            }

                            let delta = part.text
                            textContent = (textContent ?? "") + (delta ?? "")

                            if !initialed {
                                continuation.yield(.itemAdded(.init(event: .itemAdded, data: .message(.init(id: "", index: nil, content: [])))))
                                // Because each candidate will generate a corresponding contentDelta, content is set to nil here.
                                continuation.yield(.contentAdded(.init(event: .contentAdded, data: .text(.init(delta: delta, content: nil, annotations: [])))))
                            }

                            let content = TextGeneratedContent(delta: delta, content: textContent, annotations: [])
                            continuation.yield(.contentDelta(.init(event: .contentDelta, data: .text(content))))
                        }

                        let content = TextGeneratedContent(delta: nil, content: textContent, annotations: [])
                        let message = MessageItem(id: "", index: nil, content: [.text(content)])

                        if let textContent {
                            continuation.yield(.contentDone(.init(event: .contentDone, data: .text(.init(delta: nil, content: textContent, annotations: [])))))
                            continuation.yield(.itemDone(.init(event: .itemDone, data: .message(message))))
                        }

                        continuation.yield(.completed(.init(event: .completed, data: ModelResponse(
                            id: responseID,
                            context: generationConext,
                            model: model.name,
                            items: [.message(message)],
                            usage: usage,
                            stop: stop,
                            error: error
                        ))))

                        continuation.finish()
                    } catch {
                        innerSpan.recordError(error)
                        continuation.finish(throwing: error)
                    }
                    innerSpan.end()
                }

                continuation.onTermination = { _ in task.cancel() }
            }.eraseToAnyAsyncSequence()
        }
    }

    /// https://ai.google.dev/api/generate-content#method:-models.generatecontent
    func generate(
        client: ClientTransport,
        provider: LLMProviderConfiguration,
        model: LLMModel,
        _ prompt: Prompt,
        conversation: Conversation,
        logger _: Logger,
        serviceContext: ServiceContext = .current ?? .topLevel
    ) async throws -> ModelResponse {
        assert(prompt.stream == false, "The prompt perfer to use stream.")

        let decoder = JSONDecoder()
        let encoder = JSONEncoder()

        return try await withSpan("GeminiProvider Generating", context: serviceContext) { span in
            span.attributes.set("stream", value: .bool(false))
            span.attributes.set("model", value: .string(model.name))
            span.attributes.set("provoder", value: .string(provider.description))
            span.attributes.set("conversation_id", value: .string(conversation.id ?? "nil"))

            let providerURL = try require(URL(string: provider.apiURL), error: RuntimeError.invalidApiURL(provider.apiURL))

            let body = Gemini.Components.Schemas.GenerateContentRequest(prompt, history: conversation)

            // Build Request
            let request = HTTPRequest(
                method: .post,
                scheme: nil,
                authority: nil,
                path: "/models/\(model.name):generateContent",
                headerFields: [
                    .contentType: "application/json",
                    .init("x-goog-api-key")!: provider.apiKey,
                ]
            )

            let bodyData = try encoder.encode(body)

            // Send Request
            let (response, _responseBody) = try await client.send(request, body: .init(bodyData), baseURL: providerURL, operationID: UUID().uuidString)

            span.attributes.set("response.status.code", value: .init(integerLiteral: response.status.code))
            span.attributes.set("response.status.message", value: .string(response.status.description))

            guard response.status == .ok else {
                let e = try await _responseBody |> { try await String(collecting: $0, upTo: .max) }
                throw RuntimeError.httpError(response.status, e)
            }

            let responseBody = try _responseBody ?? RuntimeError.emptyResponseBody

            let data: Data; do {
                data = try await Data(collecting: responseBody, upTo: .max)
            } catch {
                span.attributes.set("response.headers", value: .string(response.headerFields.debugDescription))
                span.attributes.set("response.body.length", value: .string(String(describing: responseBody.length)))
                throw error
            }

            do {
                let contentResposne = try decoder.decode(Gemini.Components.Schemas.GenerateContentResponse.self, from: data)
                return ModelResponse(contentResposne, .init(conversationID: conversation.id, provider: provider))
            } catch {
                span.setStatus(.init(code: .error))
                span.recordError(error, attributes: .init(["response.body": .string(String(data: data, encoding: .utf8) ?? "nil")]))
                throw error
            }
        }
    }
}
