// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import HTTPTypes
import LazyKit
import NetworkKit
import OpenAPIRuntime
import SynchronizationKit

public protocol PromptPart {}

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
        model: LLMModelReference
    ) async throws -> AnyAsyncSequence<ModelStreamResponse> {
        assert(prompt.stream == true, "The prompt perfer do not use stream.")

        let provider = model.provider.type.provider
        
        let stream = try await provider.send(client: client, provider: model.provider, model: model.model, prompt)
        
        return stream
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
