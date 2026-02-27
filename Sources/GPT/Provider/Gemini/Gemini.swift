import Atomics
import Foundation
import Gemini
import HTTPTypes
import LazyKit
import Logging
import NetworkKit
import OpenAPIRuntime
import ServiceContextModule
import TraceKit
import Tracing
import Swiftic

struct GeminiProvider: LLMProvider {
    func generate(
        client: ClientTransport,
        provider: LLMProviderConfiguration,
        model: LLMModel,
        _ prompt: Prompt,
        conversation: Conversation,
        logger: Logger,
        serviceContext: ServiceContext = .current ?? .topLevel
    ) async throws -> AnyAsyncSequence<ModelStreamResponse> {
        assert(prompt.stream == true, "The prompt perfer do not use stream.")
        return try await withSpan("GeminiProvider Generating", context: serviceContext) { span in
            span.attributes.set("stream", value: .bool(true))
            span.attributes.set("model", value: .string(model.name))
            span.attributes.set("provoder", value: .string(provider.description))
            span.attributes.set("conversation_id", value: .string(conversation.id ?? "nil"))
            
            let providerURL = try require(URL(string: provider.apiURL), error: RuntimeError.invalidApiURL(provider.apiURL))
            
            let body = Google_Ai_Generativelanguage_V1beta_GenerateContentRequest(prompt, history: conversation)
            
            // Build Request
            let request = HTTPRequest(
                method: .post,
                scheme: nil,
                authority: nil,
                path: "/models/\(model.name):streamGenerateContent?alt=sse",
                headerFields: [
                    .contentType: "application/json",
                    .init("x-goog-api-key")!: provider.apiKey
                ]
            )
            
            let (response, _responseBody) = try await client.send(request, body: .init(body.jsonUTF8Data()), baseURL: providerURL, operationID: UUID().uuidString)
            
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
                        try Google_Ai_Generativelanguage_V1beta_GenerateContentResponse(jsonString: $0.data)
                    }
                    
                    let generationConext = GenerationConext(conversationID: conversation.id)
                    
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
                            responseID = response.responseID
                            
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
                            
                            let candidate = response.candidates.first
                            let blockReason = response.promptFeedback.blockReason
                            
                            if blockReason != .unspecified {
                                error = .init(code: String(blockReason.rawValue), message: nil)
                            }
                            
                            usage = TokenUsage(
                                input: Int(response.usageMetadata.promptTokenCount),
                                output: Int(response.usageMetadata.candidatesTokenCount),
                                total: Int(response.usageMetadata.totalTokenCount)
                            )
                            
                            guard let candidate, let part = candidate.content.parts.first else {
                                break
                            }
                            
                            let finishReason = candidate.finishReason
                            if finishReason != .unspecified {
                                stop = GenerationStop(code: String(finishReason.rawValue), message: candidate.finishMessage)
                            }
                            
                            let delta = part.text
                            textContent = (textContent ?? "") + delta
                            
                            if !initialed {
                                continuation.yield(.itemAdded(.init(event: .itemAdded, data: .message(.init(id: "", index: nil, content: [])))))
                                continuation.yield(.contentAdded(.init(event: .contentAdded, data: .text(.init(delta: delta, content: textContent, annotations: [])))))
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
    
    // https://ai.google.dev/api/generate-content#method:-models.generatecontent
    func generate(
        client: ClientTransport,
        provider: LLMProviderConfiguration,
        model: LLMModel,
        _ prompt: Prompt,
        conversation: Conversation,
        logger: Logger,
        serviceContext: ServiceContext = .current ?? .topLevel
    ) async throws -> ModelResponse {
        assert(prompt.stream == false, "The prompt perfer to use stream.")
        return try await withSpan("GeminiProvider Generating", context: serviceContext) { span in
            span.attributes.set("stream", value: .bool(false))
            span.attributes.set("model", value: .string(model.name))
            span.attributes.set("provoder", value: .string(provider.description))
            span.attributes.set("conversation_id", value: .string(conversation.id ?? "nil"))
            
            let providerURL = try require(URL(string: provider.apiURL), error: RuntimeError.invalidApiURL(provider.apiURL))

            let body = Google_Ai_Generativelanguage_V1beta_GenerateContentRequest(prompt, history: conversation)

            // Build Request
            let request = HTTPRequest(
                method: .post,
                scheme: nil,
                authority: nil,
                path: "/models/\(model.name):generateContent",
                headerFields: [
                    .contentType: "application/json",
                    .init("x-goog-api-key")!: provider.apiKey
                ]
            )

            // Send Request
            let (response, _responseBody) = try await client.send(request, body: .init(body.jsonUTF8Data()), baseURL: providerURL, operationID: UUID().uuidString)

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
                let contentResposne = try Google_Ai_Generativelanguage_V1beta_GenerateContentResponse(jsonUTF8Data: data)
                return ModelResponse(contentResposne, .init(conversationID: conversation.id))
            } catch {
                span.setStatus(.init(code: .error))
                span.recordError(error, attributes: .init(["response.body": .string(String(data: data, encoding: .utf8) ?? "nil")]))
                throw error
            }
        }
    }
}
