//
//  OpenAI.swift
//  swift-gpt
//
//  Created by AFuture on 2025/7/19.
//

import Foundation
import LazyKit
import HTTPTypes
import OpenAPIRuntime
import NetworkKit

struct OpenAIProvider: LLMProvider {
    
    func send(
        client: ClientTransport,
        provider: LLMProviderConfiguration,
        model: LLMModel,
        _ prompt: Prompt
    ) async throws -> AnyAsyncSequence<ModelStreamResponse> {
        assert(prompt.stream == true, "The prompt perfer do not use stream.")
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        guard let providerURL = URL(string: provider.apiURL) else {
            throw RuntimeError.invalidApiURL(provider.apiURL)
        }
        
        let url = providerURL.appending(path: "responses")
        
        let request = HTTPRequest(
            method: .post,
            scheme: nil,
            authority: nil,
            path: nil,
            headerFields: [
                .contentType: "application/json",
                .authorization: "Bearer \(provider.apiKey)",
            ]
        )
        
        let body = OpenAIModelReponseRequest(prompt, model: model.name, stream: true)
        let bodyData = try encoder.encode(body)
        
        // Send Request
        let (response, responseBody) = try await client.send(
            request,
            body: .init(bodyData),
            baseURL: url,
            operationID: UUID().uuidString
        )
        
        guard response.status == .ok else {
            let errorStr: String? =
            if let responseBody {
                try await String(collecting: responseBody, upTo: .max)
            } else {
                nil
            }
            throw RuntimeError.httpError(response.status, errorStr)
        }
        
        guard
            let contentType = response.headerFields.contentType,
            contentType.starts(with: ServerSentEvent.MIME_String)
        else {
            throw RuntimeError.reveiveUnsupportedContentTypeInResponse
        }
        
        guard let responseBody else {
            throw RuntimeError.emptyResponseBody
        }
        
        return responseBody.map {
            Data($0)
        }.mapToServerSentEvert().map {
            try decoder.decode(OpenAIModelStreamResponse.self, from: Data($0.data.utf8))
        }.map {
            ModelStreamResponse($0)
        }.compacted().eraseToAnyAsyncSequence()
    }
}
