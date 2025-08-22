//
//  Provider.swift
//  swift-gpt
//
//  Created by AFuture on 2025/7/19.
//

import LazyKit

/// Internal mapping from provider type to provider implementation.
extension LLMProviderType {
    /// The concrete provider implementation for this provider type.
    var provider: any LLMProvider {
        switch self {
        case .OpenAI:
            return OpenAIProvider()
        case .OpenAICompatible:
            return OpenAICompatibleProvider()
        case .Gemini:
            fatalError("Not Implemented")
        }
    }
}
