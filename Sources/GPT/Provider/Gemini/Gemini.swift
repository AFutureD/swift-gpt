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

struct GeminiProvider: LLMProvider {
    func generate(
        client _: ClientTransport,
        provider _: LLMProviderConfiguration,
        model _: LLMModel,
        _: Prompt,
        conversation _: Conversation,
        logger _: Logger,
        serviceContext _: ServiceContext = .current ?? .topLevel
    ) async throws -> AnyAsyncSequence<ModelStreamResponse> {
        todo()
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
        _ = client
        _ = provider
        _ = model
        _ = prompt
        _ = conversation
        _ = logger
        _ = serviceContext

        guard let providerURL = URL(string: provider.apiURL) else {
            throw RuntimeError.invalidApiURL(provider.apiURL)
        }
        
        var body = Google_Ai_Generativelanguage_V1beta_GenerateContentRequest(prompt, history: conversation)

        // Build Request
        let request = HTTPRequest(
            method: .post,
            scheme: nil,
            authority: nil,
            path: nil,
            headerFields: [
                .contentType: "application/json",
                .init("x-goog-api-key")!: provider.apiKey
            ]
        )

        // Send Request
        let url = providerURL.appending(path: "models/\(model.name):generateContent")
        let (response, responseBody) = try await client.send(request, body: .init(body.jsonUTF8Data()), baseURL: url, operationID: UUID().uuidString)

        guard response.status == .ok else {
            let errorStr: String? = if let responseBody {
                try await String(collecting: responseBody, upTo: .max)
            } else {
                nil
            }
            throw RuntimeError.httpError(response.status, errorStr)
        }
        
        guard let responseBody else {
            throw RuntimeError.emptyResponseBody
        }

        let data = try await Data(collecting: responseBody, upTo: .max)
        let contentResposne = try Google_Ai_Generativelanguage_V1beta_GenerateContentResponse(jsonUTF8Data: data)
        
        return ModelResponse(contentResposne, .init(conversationID: conversation.id))
    }
}
