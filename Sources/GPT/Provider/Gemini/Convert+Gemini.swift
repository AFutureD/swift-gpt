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


private func convert(inputs: [Prompt.Input]) -> [Google_Ai_Generativelanguage_V1beta_Part] {
    var items: [Google_Ai_Generativelanguage_V1beta_Part] = []
    for input in inputs {
        switch input {
        case .text(let text):
            var p = Google_Ai_Generativelanguage_V1beta_Part()
            p.text = text.content
            items.append(p)
        default:
            continue
        }
    }
    return items
}

private func convert(conversationItems inputs: [ConversationItem]) -> [Google_Ai_Generativelanguage_V1beta_Content] {
    var items: [Google_Ai_Generativelanguage_V1beta_Content] = []
    for input in inputs {
        switch input {
        case .input(let input):
            var content = Google_Ai_Generativelanguage_V1beta_Content()
            content.role = "user"
            content.parts = convert(inputs: [input])
            items.append(content)
        
        case .generated(let item):
            var input = Google_Ai_Generativelanguage_V1beta_Content()
            input.role = "model"
            var content = Google_Ai_Generativelanguage_V1beta_Content(item)
            
        }
    }
    return items
}

extension Google_Ai_Generativelanguage_V1beta_Content {
    init?(_ generatedItem: GeneratedItem) {
        self.init()
        
        self.role = "model"
        
        switch generatedItem {
        case .message(let messageItem):
            self.parts = messageItem.content?.compactMap { Google_Ai_Generativelanguage_V1beta_Part($0) } ?? []
        }
    }
}

extension Google_Ai_Generativelanguage_V1beta_Part {
    init?(_ content: MessageContent) {
        switch content {
        case .text(let textGeneratedContent):
            self.init()
            guard let text = textGeneratedContent.content else {
                return nil
            }
            self.text = text
        case .refusal(let textRefusalGeneratedContent):
            return nil
        }
    }
}

extension Google_Ai_Generativelanguage_V1beta_GenerateContentRequest {
    init(_ prompt: Prompt, history: Conversation) {
        self.init()
        
        let instructions = prompt.instructions
        let contextControl = prompt.context
        let generationControl = prompt.generation
        
        var historyItems = history.items
        historyItems.removeAll {
            guard case .input(let input) = $0, let instructions else {
                return false
            }

            switch instructions {
            case .text(let value):
                return input.role == .system && input.text?.content == value
            case .inputs(let value):
                return value.contains(input)
            }
        }

        // Instructions
        var instructionParts: [Google_Ai_Generativelanguage_V1beta_Part] = []
        switch instructions {
        case .text(let text):
            var p = Google_Ai_Generativelanguage_V1beta_Part()
            p.text = text
            instructionParts.append(p)
        case .inputs(let array):
            instructionParts.append(contentsOf: convert(inputs: array))
        default:
            break
        }
        
        var items: [Google_Ai_Generativelanguage_V1beta_Content] = []
        
        // History
        let lastK = if let maxItemCount = contextControl?.maxItemCount {
            max(0, maxItemCount - prompt.inputs.count)
        } else {
            historyItems.count
        }
        items.append(contentsOf: convert(conversationItems: historyItems.suffix(lastK)))

        // Inputs
        var input = Google_Ai_Generativelanguage_V1beta_Content()
        input.parts = convert(inputs: prompt.inputs)
        input.role = "user"
        items.append(input)
        
        self.contents = items
        self.systemInstruction = Google_Ai_Generativelanguage_V1beta_Content()
        self.systemInstruction.parts = instructionParts
        
    }
}
