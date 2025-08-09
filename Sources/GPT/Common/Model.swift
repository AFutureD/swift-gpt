//
//  Model.swift
//  swift-gpt
//
//  Created by AFuture on 2025/7/12.
//

import OpenAPIRuntime
import LazyKit
import Logging

public enum LLMProviderType: String, Hashable, Codable, Sendable {
    case OpenAI
    case OpenAICompatible
    case Gemini
}

protocol LLMProvider: Sendable {
    func send(
        client: ClientTransport,
        provider: LLMProviderConfiguration,
        model: LLMModel,
        _ prompt: Prompt,
        logger: Logger
    ) async throws -> AnyAsyncSequence<ModelStreamResponse>
}

public struct LLMProviderConfiguration: Hashable, Codable, Sendable {
    public let type: LLMProviderType
    
    public let name: String
    public let apiKey: String
    public let apiURL: String
    
    public init(type: LLMProviderType, name: String, apiKey: String, apiURL: String) {
        self.type = type
        self.name = name
        self.apiKey = apiKey
        self.apiURL = apiURL
    }
}

public struct LLMModel: Hashable, Codable, Sendable  {
    public let name: String
    
    public init(name: String) {
        self.name = name
    }
}

public struct LLMModelReference: Hashable, Codable, Sendable {
    public let model: LLMModel
    public let provider: LLMProviderConfiguration
    
    public init(model: LLMModel, provider: LLMProviderConfiguration) {
        self.model = model
        self.provider = provider
    }
}

public struct LLMQualifiedModel: Sendable {
    public let name: String
    
    public let models: [LLMModelReference]
    
    public init(name: String, models: [LLMModelReference]) {
        self.name = name
        self.models = models
    }
}
