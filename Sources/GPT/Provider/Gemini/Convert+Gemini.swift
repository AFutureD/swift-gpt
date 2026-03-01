// //
// //  Conert+Gemini.swift
// //  swift-gpt
// //
// //  Created by Huanan on 2026/2/23.
// //

import Gemini
import LazyKit
import Swiftic

extension ModelResponse {
    init(_ response: Components.Schemas.GenerateContentResponse, _ context: GenerationConext?) {
        let candidate = response.candidates?.first

        var stop: GenerationStop? = nil
        if let finishReason = candidate?.finishReason {
            stop = GenerationStop(code: String(finishReason.rawValue), message: candidate?.finishMessage)
        }

        var error: GenerationError? = nil
        if let blockReason = response.promptFeedback?.value1.blockReason {
            error = GenerationError(code: nil, message: String(blockReason.rawValue))
        }

        var usage: TokenUsage? = nil
        if let usageMetadata = response.usageMetadata?.value1 {
            usage = TokenUsage(
                input: Int(usageMetadata.promptTokenCount ?? 0),
                output: Int(usageMetadata.candidatesTokenCount ?? 0),
                total: Int(usageMetadata.totalTokenCount ?? 0)
            )
        }
        
        let items: [GeneratedItem] = candidate?.content?.value1.parts?.compactMap { GeneratedItem($0) } ?? []
        
        self.init(
            id: response.responseId,
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
     init?(_ part: Components.Schemas.Part) {
         if let text = part.text {
             self = .message(.init(id: "", index: nil, content: [.text(.init(delta: nil, content: text, annotations: []))]))
             return
         }
         return nil
     }
 }

// private func convert(inputs: [Prompt.Input]) -> [Google_Ai_Generativelanguage_V1beta_Part] {
//     var items: [Google_Ai_Generativelanguage_V1beta_Part] = []
//     for input in inputs {
//         switch input {
//         case .text(let text):
//             var p = Google_Ai_Generativelanguage_V1beta_Part()
//             p.text = text.content
//             items.append(p)
//         default:
//             continue
//         }
//     }
//     return items
// }

// private func convert(conversationItems inputs: [ConversationItem]) -> [Google_Ai_Generativelanguage_V1beta_Content] {
//     var items: [Google_Ai_Generativelanguage_V1beta_Content] = []
//     for input in inputs {
//         switch input {
//         case .input(let input):
//             var content = Google_Ai_Generativelanguage_V1beta_Content()
//             content.role = "user"
//             content.parts = convert(inputs: [input])
//             items.append(content)

//         case .generated(let item):
//             var input = Google_Ai_Generativelanguage_V1beta_Content()
//             input.role = "model"
//             if let content = Google_Ai_Generativelanguage_V1beta_Content(item) {
//                 items.append(content)
//             }
//         }
//     }
//     return items
// }

// extension Google_Ai_Generativelanguage_V1beta_Content {
//     init?(_ generatedItem: GeneratedItem) {
//         self.init()

//         self.role = "model"

//         switch generatedItem {
//         case .message(let messageItem):
//             self.parts = messageItem.content?.compactMap { Google_Ai_Generativelanguage_V1beta_Part($0) } ?? []
//         }
//     }
// }

// extension Google_Ai_Generativelanguage_V1beta_Part {
//     init?(_ content: MessageContent) {
//         switch content {
//         case .text(let textGeneratedContent):
//             self.init()
//             guard let text = textGeneratedContent.content else {
//                 return nil
//             }
//             self.text = text
//         case .refusal(let textRefusalGeneratedContent):
//             return nil
//         }
//     }
// }

// extension Google_Ai_Generativelanguage_V1beta_GenerationConfig {
//     init(_ control: GenerationControl?) {
//         self.init()

//         guard let control else { return }

//         self.temperature = control.temperature |> Float.init ?? 0.0
//         self.topP = control.topP |> Float.init ?? 0.0
//         self.maxOutputTokens = control.maxTokens |> Int32.init ?? 0
//     }
// }

// extension Google_Ai_Generativelanguage_V1beta_GenerateContentRequest {
//     init(_ prompt: Prompt, history: Conversation) {
//         self.init()

//         let instructions = prompt.instructions
//         let contextControl = prompt.context
//         let generationControl = prompt.generation

//         var historyItems = history.items
//         historyItems.removeAll {
//             guard case .input(let input) = $0, let instructions else {
//                 return false
//             }

//             switch instructions {
//             case .text(let value):
//                 return input.role == .system && input.text?.content == value
//             case .inputs(let value):
//                 return value.contains(input)
//             }
//         }

//         // Instructions
//         var instructionParts: [Google_Ai_Generativelanguage_V1beta_Part] = []
//         switch instructions {
//         case .text(let text):
//             var p = Google_Ai_Generativelanguage_V1beta_Part()
//             p.text = text
//             instructionParts.append(p)
//         case .inputs(let array):
//             instructionParts.append(contentsOf: convert(inputs: array))
//         default:
//             break
//         }

//         var items: [Google_Ai_Generativelanguage_V1beta_Content] = []

//         // History
//         let lastK = if let maxItemCount = contextControl?.maxItemCount {
//             max(0, maxItemCount - prompt.inputs.count)
//         } else {
//             historyItems.count
//         }
//         items.append(contentsOf: convert(conversationItems: historyItems.suffix(lastK)))

//         // Inputs
//         var input = Google_Ai_Generativelanguage_V1beta_Content()
//         input.parts = convert(inputs: prompt.inputs)
//         input.role = "user"
//         items.append(input)

//         self.contents = items
//         self.systemInstruction = Google_Ai_Generativelanguage_V1beta_Content()
//         self.systemInstruction.parts = instructionParts
//         self.generationConfig = Google_Ai_Generativelanguage_V1beta_GenerationConfig(generationControl)

//     }
// }

extension Components.Schemas.Part {
    init?(_ input: Prompt.Input) {
        switch input {
        case .text(let text):
            self.init(text: text.content)
        case .file:
            return nil
        case .image:
            return nil
        }
    }
}

extension Gemini.Components.Schemas.Content {
    init(_ instructions: Prompt.Instructions) {
        switch instructions {
        case .text(let string):
            self.init(parts: [.init(text: string)])
        case .inputs(let inputs):
            self.init(inputs)
        }
    }

    init(_ inputs: [Prompt.Input]) {
        self.init(parts: inputs.compactMap { .init($0) })
    }
}

extension Gemini.Components.Schemas.Part {
    init?(_ content: MessageContent) {
        switch content {
        case .text(let textGeneratedContent):
            self.init(text: textGeneratedContent.content)
        case .refusal:
            return nil
        }
    }
}

// https://ai.google.dev/gemini-api/docs/thinking#thinking-levels
extension Components.Schemas.ThinkingConfig.ThinkingLevelPayload {
    init?(_ level: GenerationControl.ThinkingLevel) {
        switch level {
        case .low:
            self = .low
        case .medium:
            self = .medium
        case .high:
            self = .high
        case .custom(let value):
            switch value {
            case "minimal":
                self = .minimal
            default:
                return nil
            }
        }
    }
}

extension Gemini.Components.Schemas.ThinkingConfig {
    init(_ cfg: GenerationControl.ThinkingControl) {
        self.init(includeThoughts: cfg.includeInResponse,
                  thinkingLevel: cfg.level |> Components.Schemas.ThinkingConfig.ThinkingLevelPayload.init)
    }
}

extension Gemini.Components.Schemas.GenerationConfig {
    init(_ cfg: GenerationControl) {
        let thinkConfig = cfg.thinking
            |> Gemini.Components.Schemas.ThinkingConfig.init
            |> Components.Schemas.GenerationConfig.ThinkingConfigPayload.init(value1:)

        self.init(maxOutputTokens: cfg.maxTokens |> Int32.init,
                  temperature: cfg.temperature |> Float.init,
                  topP: cfg.topP |> Float.init,
                  thinkingConfig: thinkConfig)
    }
}

extension Gemini.Components.Schemas.Content {
    init?(_ item: ConversationItem) {
        switch item {
        case .input(let input):
            switch input {
            case .text(let text):
                self.init(parts: [.init(text: text.content)], role: "user")
            case .file:
                return nil
            case .image:
                return nil
            }
        case .generated(let generatedItem):
            switch generatedItem {
            case .message(let messageItem):
                let content = messageItem.content
                self.init(parts: content?.compactMap { .init($0) }, role: "model")
            }
        }
    }
}

extension Gemini.Components.Schemas.GenerateContentRequest {
    init(_ prompt: Prompt, history: Conversation) {
        let instructions = prompt.instructions
        let contextControl = prompt.context

        var historyItems = history.items
        historyItems.remove(instructions)

        // History
        let lastK = if let maxItemCount = contextControl?.maxItemCount {
            max(0, maxItemCount - prompt.inputs.count)
        } else {
            historyItems.count
        }

        var content: [Gemini.Components.Schemas.Content] = []
        content.append(contentsOf: historyItems.suffix(lastK).compactMap { Gemini.Components.Schemas.Content($0) })
        content.append(Components.Schemas.Content(prompt.inputs))

        self.init(model: "",
                  systemInstruction: prompt.instructions |> { .init(value1: .init($0)) },
                  contents: content,
                  toolConfig: nil,
                  safetySettings: nil,
                  generationConfig: prompt.generation |> { .init(value1: .init($0)) },
                  cachedContent: nil)
    }
}

extension [ConversationItem] {
    mutating func remove(_ instructions: Prompt.Instructions?) {
        self.removeAll {
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
    }
}
