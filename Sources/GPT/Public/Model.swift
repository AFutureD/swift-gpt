//
//  Model.swift
//  swift-gpt
//
//  Created by AFuture on 2025/7/12.
//

import LazyKit
import Logging
import OpenAPIRuntime
import ServiceContextModule

// MARK: LLMProviderType

/// An enumeration of the supported LLM provider types.
public enum LLMProviderType: String, Hashable, Codable, Sendable {
    /// For OpenAI's official API.
    case OpenAI
    /// For services that are compatible with the OpenAI API.
    case OpenAICompatible
    /// For Google's Gemini models.
    case Gemini
}

// MARK: LLMProvider

protocol LLMProvider: Sendable {
    func generate(
        client: ClientTransport,
        provider: LLMProviderConfiguration,
        model: LLMModel,
        _ prompt: Prompt,
        conversation: Conversation,
        logger: Logger,
        serviceContext: ServiceContext
    ) async throws -> AnyAsyncSequence<ModelStreamResponse>

    func generate(
        client: ClientTransport,
        provider: LLMProviderConfiguration,
        model: LLMModel,
        _ prompt: Prompt,
        conversation: Conversation,
        logger: Logger,
        serviceContext: ServiceContext
    ) async throws -> ModelResponse
}

// MARK: LLMProviderConfiguration

/// Configuration for an LLM provider.
public struct LLMProviderConfiguration: Hashable, Codable, Sendable {
    /// The type of the provider.
    public let type: LLMProviderType

    /// A user-defined name for the provider configuration.
    public let name: String
    /// The API key for the provider.
    public let apiKey: String
    /// The base URL for the provider's API.
    public let apiURL: String

    /// Creates a new provider configuration.
    ///
    /// - Parameters:
    ///   - type: The type of the provider.
    ///   - name: A user-defined name for the configuration.
    ///   - apiKey: The API key for the provider.
    ///   - apiURL: The base URL for the provider's API.
    public init(type: LLMProviderType, name: String, apiKey: String, apiURL: String) {
        self.type = type
        self.name = name
        self.apiKey = apiKey
        self.apiURL = apiURL
    }
}

extension LLMProviderConfiguration: CustomStringConvertible {
    public var description: String {
        "LLMProviderConfiguration(type: '\(type)', name: '\(name)', url: '\(apiURL)', key: '\(apiKey.prefix(4))****\(apiKey.suffix(4))')"
    }
}

// MARK: LLMModel

/// Represents a specific LLM model.
public struct LLMModel: Hashable, Codable, Sendable {
    /// The name of the model (e.g., "gpt-4o").
    public let name: String

    public init(name: String) {
        self.name = name
    }
}

// MARK: LLMModelReference

/// A reference to a specific model from a specific provider.
public struct LLMModelReference: Hashable, Codable, Sendable {
    /// The model being referenced.
    public let model: LLMModel
    /// The provider of the model.
    public let provider: LLMProviderConfiguration

    public init(model: LLMModel, provider: LLMProviderConfiguration) {
        self.model = model
        self.provider = provider
    }
}

public extension LLMModelReference {
    var name: String {
        "\(provider.name)/\(model.name)"
    }
}

extension LLMModelReference: CustomStringConvertible {
    public var description: String {
        "LLMModelReference(model: '\(model)', provider: '\(provider)')"
    }
}

// MARK: LLMQualifiedModel

/// A qualified model that can include multiple model references, used for fallbacks and retries.
public struct LLMQualifiedModel: Sendable {
    /// A user-defined name for the qualified model.
    public let name: String

    /// A list of model references to be tried in sequence.
    public let models: [LLMModelReference]

    /// Creates a new qualified model.
    ///
    /// - Parameters:
    ///   - name: A user-defined name for the qualified model.
    ///   - models: A list of model references to be tried in sequence.
    public init(name: String, models: [LLMModelReference]) {
        self.name = name
        self.models = models
    }
}
