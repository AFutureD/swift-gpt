//
//  OpenAIComPatible.swift
//  swift-gpt
//
//  Created by AFuture on 2025/7/19.
//

import AsyncAlgorithms
import Foundation
import HTTPTypes
import LazyKit
import Logging
import NetworkKit
import OpenAPIRuntime
import ServiceContextModule
import Tracing

struct OpenAICompatibleProvider: LLMProvider {
    func generate(
        client: any OpenAPIRuntime.ClientTransport,
        provider: LLMProviderConfiguration,
        model: LLMModel,
        _ prompt: Prompt,
        conversation: Conversation,
        logger: Logging.Logger,
        serviceContext: ServiceContext = .current ?? .topLevel
    ) async throws -> ModelResponse {
        assert(prompt.stream == false, "The prompt perfer to use stream.")
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        return try await withSpan("OpenAICompatibleProvider Generating") { span in
            span.attributes.set("stream", value: .bool(false))
            span.attributes.set("model", value: .string(model.name))
            span.attributes.set("provoder", value: .string(provider.description))
            span.attributes.set("conversation_id", value: .string(conversation.id ?? "nil"))
            
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
            
            span.attributes.set("response.status.code", value: .init(integerLiteral: response.status.code))
            span.attributes.set("response.status.message", value: .string(response.status.description))
            
            // Handle Response
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
            
            do {
                let openAIChatCompletionResponse = try decoder.decode(OpenAIChatCompletionResponse.self, from: data)
                let modelReponse = ModelResponse(openAIChatCompletionResponse, .init(conversationID: conversation.id))
                return modelReponse
            } catch {
                span.setStatus(.init(code: .error))
                span.recordError(error, attributes: .init(["response.body": .string(String(data: data, encoding: .utf8) ?? "nil")]))
                throw error
            }
        }
    }

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
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        return try await withSpan("OpenAICompatibleProvider Generating", context: serviceContext) { span in
            span.attributes.set("stream", value: .bool(true))
            span.attributes.set("model", value: .string(model.name))
            span.attributes.set("provoder", value: .string(provider.description))
            span.attributes.set("conversation_id", value: .string(conversation.id ?? "nil"))
            
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
            let (response, responseBody) = try await withSpan("Waiting Response", context: span.context) { _ in
                try await client.send(
                    request,
                    body: .init(bodyData),
                    baseURL: url,
                    operationID: UUID().uuidString
                )
            }
            
            span.attributes.set("response.status.code", value: .init(integerLiteral: response.status.code))
            span.attributes.set("response.status.message", value: .string(response.status.description))
            
            guard response.status == .ok else {
                let errorStr: String? = if let responseBody {
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
            }.aggregateToModelStremResponse(
                with: .init(conversationID: conversation.id)
            ).withSpan("Receive Response", childName: "Generating", context: span.context).eraseToAnyAsyncSequence()
        }
    }
}
