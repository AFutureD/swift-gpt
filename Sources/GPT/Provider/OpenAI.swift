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
import Logging

struct OpenAIProvider: LLMProvider {
    
    /// Sends a non-streaming completion request to the configured provider and returns the parsed ModelResponse.
    /// 
    /// The function POSTs a JSON payload to `<provider.apiURL>/responses` containing the given `prompt`, `conversation` as history, the `model` name, and `stream: false`. The `prompt` must have `stream == false`.
    /// 
    /// - Parameters:
    ///   - model: The model to use (its `name` is sent to the provider).
    ///   - prompt: The prompt to generate from (must not request streaming).
    ///   - conversation: Conversation history to include as the request's `history`.
    /// - Returns: A ModelResponse constructed from the provider's JSON response.
    /// - Throws:
    ///   - `RuntimeError.invalidApiURL` if `provider.apiURL` is not a valid URL.
    ///   - `RuntimeError.httpError` when the HTTP status is not OK (includes optional error body string).
    ///   - `RuntimeError.emptyResponseBody` if the response contains no body.
    func generate(
        client: ClientTransport,
        provider: LLMProviderConfiguration,
        model: LLMModel,
        _ prompt: Prompt,
        conversation: Conversation,
        logger: Logger
    ) async throws -> ModelResponse {
        assert(prompt.stream == false, "The prompt perfer to use stream.")
        
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

        let body = OpenAIModelReponseRequest(prompt, history: conversation, model: model.name, stream: false)
        let bodyData = try encoder.encode(body)
        
        // Send Request
        let (response, responseBody) = try await client.send(
            request,
            body: .init(bodyData),
            baseURL: url,
            operationID: UUID().uuidString
        )
        
        
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
        let openaiModelResponse = try decoder.decode(OpenAIModelReponse.self, from: data)
        let modelReponse = ModelResponse(openaiModelResponse)
        
        return modelReponse
    }

    
    /// Sends the prompt (as a streaming request) to the provider and returns an async sequence of partial model responses.
    /// 
    /// This constructs and POSTs an OpenAI-style responses request with the given prompt and conversation history, expects a Server-Sent Events (SSE) response, and yields decoded `ModelStreamResponse` items as they arrive.
    /// - Note: `prompt.stream` must be `true`.
    /// - Parameters:
    ///   - prompt: The prompt to send. Must have streaming enabled.
    ///   - conversation: Conversation history to include in the request payload.
    /// - Returns: An `AnyAsyncSequence<ModelStreamResponse>` that emits incremental responses from the model.
    /// - Throws:
    ///   - `RuntimeError.invalidApiURL` if `provider.apiURL` is not a valid URL.
    ///   - `RuntimeError.httpError` if the HTTP status is not OK (includes server error message when available).
    ///   - `RuntimeError.reveiveUnsupportedContentTypeInResponse` if the response is not SSE (`text/event-stream`).
    ///   - `RuntimeError.emptyResponseBody` if the response body is missing.
    ///   - Decoding errors if an SSE event payload cannot be decoded into `OpenAIModelStreamResponse`.
    func generate(
        client: ClientTransport,
        provider: LLMProviderConfiguration,
        model: LLMModel,
        _ prompt: Prompt,
        conversation: Conversation,
        logger: Logger
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

        let body = OpenAIModelReponseRequest(prompt, history: conversation, model: model.name, stream: true)
        let bodyData = try encoder.encode(body)
        
        // Send Request
        let (response, responseBody) = try await client.send(
            request,
            body: .init(bodyData),
            baseURL: url,
            operationID: UUID().uuidString
        )
        
        guard response.status == .ok else {
            let errorStr: String? = if let responseBody {
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
