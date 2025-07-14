//
//  Untitled.swift
//  swift-gpt
//
//  Created by AFuture on 2025/7/12.
//

extension OpenAIModelReponseRequest {
    init(_ prompt: Prompt, model: String) {
        self.init(
            input: prompt.inputs,
            model: model,
            background: nil, // TODO: suppert backgroud mode.
            include: nil,
            instructions: prompt.instructions,
            maxOutputTokens: nil,
            metadata: nil,
            parallelToolCalls: false,
            previousResponseId: prompt.prev_id,
            reasoning: nil, // TODO: Add reasning configuration
            store: prompt.store,
            stream: true,
            temperature: nil,
            text: nil, // TODO: add expected ouput format support
            toolChoice: nil,
            tools: nil,
            topP: nil,
            truncation: nil,
            user: nil // TODO: provide session ID or user ID
        )
    }
}

extension OpenAIChatCompletionRequestMessageContentPart {
    init?(item: OpenAIModelReponseRequestInputItemMessageContentItem) {
        switch item {
        case .text(let text):
            self = .text(.init(text: text.text))
        case .file(let file):
            self = .file(.init(file: .init(fileId: file.fileID, filename: file.filename, fileData: file.fileData)))
        default:
            return nil
        }
    }
}

extension OpenAIChatCompletionRequestMessageContentPart {
    
}

extension OpenAIChatCompletionRequestMessage {
    init(_ item: OpenAIModelReponseRequestInputItemMessage) {
        
        let content: OpenAIChatCompletionRequestMessageContent
        
        switch item.content {
        case .text(let text):
            content = .text(text)
        case .inputs(let contentItems):
            let parts = contentItems.compactMap {
                OpenAIChatCompletionRequestMessageContentPart(item: $0)
            }
            content = .parts(parts)
        }
        
        switch item.role {
        case .assistant:
            self = .assistant(.init(audio: nil, content: content, name: nil, refusal: nil, tool_calls: nil))
        case .developer:
            self = .developer(.init(content: content, name: nil))
        case .user:
            self = .user(.init(content: content, name: nil))
        case .system:
            self = .system(.init(content: content, name: nil))
        }
    }
}

extension OpenAIChatCompletionRequestMessage {
    init?(_ item: OpenAIModelReponseContext) {
        switch item {
        case .input(let input):
            let parts = input.content.compactMap {
                OpenAIChatCompletionRequestMessageContentPart(item: $0)
            }
            
            let content: OpenAIChatCompletionRequestMessageContent = .parts(parts)
            switch input.role {
            case .developer:
                self = .developer(.init(content: content, name: nil))
            case .user:
                self = .user(.init(content: content, name: nil))
            case .system:
                self = .system(.init(content: content, name: nil))
            }
        case .output(let output):
            let parts: [OpenAIChatCompletionRequestMessageContentPart] = output.content.compactMap {
                switch $0 {
                case .text(let text):
                        .text(.init(text: text.text))
                default:
                    nil
                }
            }
            
            self = .assistant(.init(audio: nil, content: .parts(parts), name: nil, refusal: nil, tool_calls: nil))
        default:
            return nil
        }
    }
}

extension OpenAIChatCompletionRequest {
    init(_ prompt: Prompt, model: String) {
        var messages: [OpenAIChatCompletionRequestMessage] = []
        switch prompt.inputs {
        case .text(let text):
            messages.append(.user(.init(content: .text(text), name: nil)))
        case .items(let items):
            for item in items {
                switch item {
                case .message(let message):
                    messages.append(OpenAIChatCompletionRequestMessage(message))
                case .output(let output):
                    messages.append(OpenAIChatCompletionRequestMessage(output)!)
                case .reference(_):
                    break
                }
            }
        }
        self.init(
            messages: messages,
            model: model,
            audio: nil,
            frequencyPenalty: nil,
            logitBias: nil,
            logprobs: nil,
            maxCompletionTokens: nil,
            metadata: nil,
            modalities: nil,
            n: nil,
            parallelToolCalls: nil,
            prediction: nil,
            presencePenalty: nil,
            reasoningEffort: nil,
            responseFormat: nil,
            seed: nil,
            serviceTier: nil,
            stop: nil,
            store: prompt.store,
            stream: true,
            streamOptions: .init(includeUsage: true),
            temperature: nil,
            toolChoice: nil,
            tools: nil,
            topLogprobs: nil,
            topP: nil,
            user: nil,
            webSearchOptions: nil
        )
    }
}
