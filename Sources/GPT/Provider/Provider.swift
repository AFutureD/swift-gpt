//
//  Provider.swift
//  swift-gpt
//
//  Created by AFuture on 2025/7/19.
//

import LazyKit

extension LLMProviderType {
    var provider: any LLMProvider {
        switch self {
        case .OpenAI:
            return OpenAIProvider()
        case .OpenAICompatible:
            return OpenAICompatibleProvider()
        case .Gemini:
            todo("Unsupported Yet")
        }
    }
}
