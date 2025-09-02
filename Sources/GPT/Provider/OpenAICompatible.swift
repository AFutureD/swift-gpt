//
//  OpenAIComPatible.swift
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
import AsyncAlgorithms

struct OpenAICompatibleProvider: LLMProvider {
    /// Generates a non-streaming chat completion from the provider using the given prompt and conversation history.
    /// 
    /// Builds an OpenAI-compatible chat completion request (stream = false), sends it to the provider's `/chat/completions` endpoint, decodes the provider response into a `ModelResponse`, and returns it.
    /// - Note: This function asserts that `prompt.stream == false` and expects a non-streaming prompt.
    /// - Parameters:
    ///   - provider: Configuration for the LLM provider (used for API URL and API key).
    ///   - model: The model to use; `model.name` is sent to the provider.
    ///   - prompt: The prompt describing the request. Must be non-streaming.
    ///   - conversation: Conversation history to include in the request body.
    /// - Returns: A `ModelResponse` constructed from the provider's completion response.
    /// - Throws:
    ///   - `RuntimeError.invalidApiURL` when `provider.apiURL` is not a valid URL.
    ///   - `RuntimeError.httpError` when the HTTP status is not OK (includes server error message when available).
    ///   - `RuntimeError.emptyResponseBody` when the response has no body.
    ///   - Any decoding or transport errors propagated from encoding/decoding or the HTTP client.
    func generate(
        client: any OpenAPIRuntime.ClientTransport,
        provider: LLMProviderConfiguration,
        model: LLMModel,
        _ prompt: Prompt, 
        conversation: Conversation, 
        logger: Logging.Logger
    ) async throws -> ModelResponse {
        assert(prompt.stream == false, "The prompt perfer to use stream.")
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        guard let providerURL = URL(string: provider.apiURL) else {
            throw RuntimeError.invalidApiURL(provider.apiURL)
        }

        // Build Request Body
        let body = OpenAIChatCompletionRequest(prompt, history: conversation, model: model.name, stream: false)
        let bodyData = try encoder.encode(body)
        
        // Build Request
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
        
        // Send Request
        let url = providerURL.appending(path: "/chat/completions")
        let (response, responseBody) = try await client.send(request, body: .init(bodyData), baseURL: url, operationID: UUID().uuidString)
        
        // Handle Response
        guard response.status == .ok else {
            let errorStr: String? =
            if let responseBody {
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
        let openAIChatCompletionResponse = try decoder.decode(OpenAIChatCompletionResponse.self, from: data)
        let modelReponse = ModelResponse(openAIChatCompletionResponse)

        return modelReponse
    }

    /// Generates a streaming chat completion from an OpenAI-compatible provider as an async sequence of ModelStreamResponse.
    ///
    /// Sends a POST request to the provider's `/chat/completions` endpoint with the given prompt and conversation history and returns an `AnyAsyncSequence` that yields aggregated `ModelStreamResponse` values for each SSE chunk until the provider emits the final `[DONE]` event.
    /// - Parameters:
    ///   - model: The LLM model to use (its `.name` is sent to the provider).
    ///   - prompt: The prompt describing the request. Must have `prompt.stream == true`.
    ///   - conversation: Conversation history to include as the request's chat history.
    /// - Returns: An `AnyAsyncSequence<ModelStreamResponse>` that produces aggregated stream responses for the ongoing completion.
    /// - Throws:
    ///   - `RuntimeError.invalidApiURL` if `provider.apiURL` is not a valid URL.
    ///   - `RuntimeError.httpError` when the provider responds with a non-OK HTTP status (the provider response body, if any, is included in the error).
    ///   - `RuntimeError.reveiveUnsupportedContentTypeInResponse` if the response Content-Type is not a Server-Sent Events (SSE) MIME type.
    ///   - `RuntimeError.emptyResponseBody` if the response contains no body to stream.
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

        // Build Request Body
        let body = OpenAIChatCompletionRequest(prompt, history: conversation, model: model.name, stream: true)
        let bodyData = try encoder.encode(body)

        // Build Request
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
        
        // Send Request
        let url = providerURL.appending(path: "/chat/completions")
        let (response, responseBody) = try await client.send(request, body: .init(bodyData), baseURL: url, operationID: UUID().uuidString)
        
        guard response.status == .ok else {
            let errorStr: String? =
            if let responseBody {
                try await String(collecting: responseBody, upTo: .max)
            } else {
                nil
            }
            throw RuntimeError.httpError(response.status, errorStr)
        }
        
        guard let contentType = response.headerFields.contentType,
              contentType.starts(with: NetworkKit.ServerSentEvent.MIME_String)
        else {
            throw RuntimeError.reveiveUnsupportedContentTypeInResponse
        }
        
        guard let responseBody else {
            throw RuntimeError.emptyResponseBody
        }
        
        return try responseBody.map {
            Data($0)
        }.mapToServerSentEvert().prefix {
            $0.data != "[DONE]"
        }.map {
            try decoder.decode(OpenAIChatCompletionStreamResponse.self, from: Data($0.data.utf8))
        }.aggregateToModelStremResponse().eraseToAnyAsyncSequence()
    }
}
