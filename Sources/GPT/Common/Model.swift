//
//  Model.swift
//  swift-gpt
//
//  Created by AFuture on 2025/7/12.
//

public enum LLMProviderType: String, Hashable, Codable, Sendable {
    case OpenAI
    case OpenAICompatible
    case Gemini
}

public struct LLMProvider: Hashable, Codable, Sendable {
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


public struct LLMQualifiedModel: Hashable, Codable, Sendable {
    public let name: String
    public let provider: LLMProvider
    
    public init(name: String, provider: LLMProvider) {
        self.name = name
        self.provider = provider
    }
}

public struct LLMModel: Sendable {
    public let name: String
    
    public let type: LLMProviderType
    public let models: [LLMQualifiedModel]
    
    public init(name: String, type: LLMProviderType, models: [LLMQualifiedModel]) {
        self.name = name
        self.models = models
        self.type = type
    }
}
