// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import HTTPTypes
import LazyKit
import NetworkKit
import OpenAPIRuntime
import SynchronizationKit

public protocol PromptPart {}

enum ModelResponse {
    case block(OpenAIModelReponse)
    case stream(AnyAsyncSequence<ModelStreamResponse>)
}

struct GPTSession: Sendable {
    let client: ClientTransport

    let sessionID: LazyLockedValue<String?> = .init(nil)

    let encoder: JSONEncoder
    let decoder: JSONDecoder

    init(client: ClientTransport, encoder: JSONEncoder = .init(), decoder: JSONDecoder = .init()) {
        self.client = client
        self.decoder = decoder
        self.encoder = encoder
    }

    func send(
        _ prompt: Prompt,
        model: LLMQualifiedModel
    ) async throws -> AnyAsyncSequence<ModelStreamResponse> {
        assert(prompt.stream == true, "The prompt perfer do not use stream.")

        switch model.provider.type {
        case .OpenAI:

            guard let providerURL = URL(string: model.provider.apiURL) else {
                todo("throw api url invalid")
            }

            let url = providerURL.appending(path: "responses")

            let request = HTTPRequest(
                method: .post,
                scheme: nil,
                authority: nil,
                path: nil,
                headerFields: [
                    .contentType: "application/json",
                    .authorization: "Bearer \(model.provider.apiKey)",
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

            // Error
            // TODO: Handle `tooManyRequests`
            guard response.status == .ok else {
                let errorStr =
                    if let responseBody {
                        try await String(collecting: responseBody, upTo: .max)
                    } else {
                        "nil"
                    }
                todo("throw errors: \(errorStr)")
            }

            guard let responseBody else {
                todo("throw empty body")
            }

            guard
                let contentType = response.headerFields.contentType,
                contentType.starts(with: NetworkKit.ServerSentEvent.MIME_String)
            else {
                // let data = try await Data(collecting: responseBody, upTo: .max)
                // let result = try JSONDecoder().decode(OpenAIModelReponse.self, from: data)
                // return .block(result)

                todo("throw error and suggest block api call")
            }

            return responseBody.map {
                Data($0)
            }.mapToServerSentEvert().map {
                try decoder.decode(OpenAIModelStreamResponse.self, from: Data($0.data.utf8))
            }.map {
                ModelStreamResponse($0)
            }.compacted().eraseToAnyAsyncSequence()
        case .OpenAICompatible:

            guard let providerURL = URL(string: model.provider.apiURL) else {
                todo("throw api url invalid")
            }

            let url = providerURL.appending(path: "/chat/completions")

            let request = HTTPRequest(
                method: .post,
                scheme: nil,
                authority: nil,
                path: nil,
                headerFields: [
                    .contentType: "application/json",
                    .authorization: "Bearer \(model.provider.apiKey)",
                ]
            )

            let body = OpenAIChatCompletionRequest(prompt, model: model.name, stream: true)
            let bodyData = try encoder.encode(body)

            let (response, responseBody) = try await client.send(
                request, body: .init(bodyData), baseURL: url, operationID: UUID().uuidString)

            // Error
            // TODO: Handle `tooManyRequests`
            guard response.status == .ok else {
                let errorStr =
                    if let responseBody {
                        try await String(collecting: responseBody, upTo: .max)
                    } else {
                        "nil"
                    }
                todo("throw errors: \(errorStr)")
            }

            guard let responseBody else {
                todo("throw empty body")
            }

            guard let contentType = response.headerFields.contentType,
                contentType.starts(with: NetworkKit.ServerSentEvent.MIME_String)
            else {
                let data = try await Data(collecting: responseBody, upTo: .max)
                let result = try JSONDecoder().decode(OpenAIChatCompletionResponse.self, from: data)
                todo("Unsupport Yet")
            }

            return responseBody.map {
                Data($0)
            }.mapToServerSentEvert().map {
                try decoder.decode(OpenAIChatCompletionStreamResponse.self, from: Data($0.data.utf8))
            }.aggregateToModelStremResponse().eraseToAnyAsyncSequence()
        case .Gemini:
            todo()
        }
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
