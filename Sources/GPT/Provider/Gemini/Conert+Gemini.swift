//
//  Conert+Gemini.swift
//  swift-gpt
//
//  Created by Huanan on 2026/2/23.
//

import Gemini
import LazyKit

extension ModelResponse {
    init(_ response: Google_Ai_Generativelanguage_V1beta_GenerateContentResponse, _ context: GenerationConext?) {
        
        let candidate = response.candidates.first
        
        var stop: GenerationStop? = nil
        if let finishReason = candidate?.finishReason {
            stop = GenerationStop(code: String(finishReason.rawValue), message: candidate?.finishMessage)
        }
        var error: GenerationError? = nil
        let blockReason = response.promptFeedback.blockReason
        if blockReason != .unspecified {
            error = GenerationError(code: String(response.promptFeedback.blockReason.rawValue), message: nil) // TODO: convert enum to string
        }
        
        let usage = TokenUsage(
            input: Int(response.usageMetadata.promptTokenCount),
            output: Int(response.usageMetadata.candidatesTokenCount),
            total: Int(response.usageMetadata.totalTokenCount)
        )

        let items: [GeneratedItem] = candidate?.content.parts.compactMap { GeneratedItem($0) } ?? []
        
        self.init(
            id: response.responseID,
            context: context,
            model: response.modelVersion,
            items: items,
            usage: usage,
            stop: stop,
            error: error
        )
    }
}

extension GeneratedItem {
    init?(_ part: Google_Ai_Generativelanguage_V1beta_Part) {
        switch part.data {
        case .text(let text):
            self = .message(.init(id: "", index: nil, content: [.text(.init(delta: nil, content: text, annotations: []))]))
        default:
            return nil
        }
    }
}
