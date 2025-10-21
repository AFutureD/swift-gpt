
import Algorithms
import AsyncAlgorithms
import LazyKit
import SynchronizationKit

extension OpenAIChatCompletionRequestMessage {
    init?(_ input: Prompt.Input) {
        switch input {
        case .text(let text):
            let part: OpenAIChatCompletionRequestMessageContentPart = .text(.init(text: text.content))
            switch text.role {
            case .system:
                self = .system(.init(content: .parts([part]), name: nil))
            case .assistant:
                self = .assistant(.init(audio: nil, content: .parts([part]), name: nil, refusal: nil, tool_calls: nil))
            case .user:
                self = .user(.init(content: .parts([part]), name: nil))
            case .developer:
                self = .developer(.init(content: .parts([part]), name: nil))
            default:
                return nil
            }
        case .file(let file):
            let part: OpenAIChatCompletionRequestMessageContentPart = .file(.init(file: .init(fileId: file.id, filename: file.filename, fileData: file.content)))
            switch file.role {
            case .system:
                self = .system(.init(content: .parts([part]), name: nil))
            case .assistant:
                self = .assistant(.init(audio: nil, content: .parts([part]), name: nil, refusal: nil, tool_calls: nil))
            case .user:
                self = .user(.init(content: .parts([part]), name: nil))
            case .developer:
                self = .developer(.init(content: .parts([part]), name: nil))
            default:
                return nil
            }
        }
    }
}

extension OpenAIChatCompletionRequestMessage {
    init?(_ item: GeneratedItem) {
        switch item {
        case .message(let message):
            let refusal: String? = message.content?.map {
                if case .refusal(let refusal) = $0 {
                    return refusal.content
                }
                return nil
            }.first ?? nil

            let parts: [OpenAIChatCompletionRequestMessageContentPart] = message.content?.compactMap { content in
                switch content {
                case .text(let text):
                    if let text = text.content {
                        return OpenAIChatCompletionRequestMessageContentPart.text(OpenAIChatCompletionRequestMessageContentTextPart(text: text))
                    }
                    return nil
                case .refusal(let refusal):
                    if let refusal = refusal.content {
                        return OpenAIChatCompletionRequestMessageContentPart.refusal(OpenAIChatCompletionRequestMessageContentRefusalPart(refusal: refusal))
                    }
                    return nil
                }
            } ?? []

            self = .assistant(.init(audio: nil, content: .parts(parts), name: nil, refusal: refusal, tool_calls: nil))
        }
    }
}

extension OpenAIChatCompletionRequest {
    init(_ prompt: Prompt, history: Conversation, model: String, stream: Bool) {
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

        var messages: [OpenAIChatCompletionRequestMessage] = []

        // instructions
        switch prompt.instructions {
        case .text(let text):
            messages.append(.system(.init(content: .text(text), name: nil)))
        case .inputs(let inputs):
            messages.append(contentsOf: inputs.compactMap { OpenAIChatCompletionRequestMessage($0) })
        case nil:
            break
        }

        let lastK = if let maxItemCount = contextControl?.maxItemCount {
            max(0, maxItemCount - prompt.inputs.count)
        } else {
            historyItems.count
        }

        // historys
        for item in historyItems.suffix(lastK) {
            switch item {
            case .input(let input):
                let message = OpenAIChatCompletionRequestMessage(input)
                if let message {
                    messages.append(message)
                }
            case .generated(let generated):
                let message = OpenAIChatCompletionRequestMessage(generated)
                if let message {
                    messages.append(message)
                }
            }
        }

        // inputs
        for input in prompt.inputs {
            let message = OpenAIChatCompletionRequestMessage(input)
            if let message {
                messages.append(message)
            }
        }

        self.init(
            messages: messages,
            model: model,
            audio: nil,
            frequencyPenalty: nil,
            logitBias: nil,
            logprobs: nil,
            maxCompletionTokens: generationControl?.maxTokens,
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
            store: generationControl?.store,
            stream: stream,
            streamOptions: stream ? .init(includeUsage: true) : nil,
            temperature: generationControl?.temperature,
            toolChoice: nil,
            tools: nil,
            topLogprobs: nil,
            topP: generationControl?.topP,
            user: nil,
            webSearchOptions: nil
        )
    }
}

extension ModelResponse {
    init(_ response: OpenAIChatCompletionResponse, _ context: GenerationConext?) {
        let usage = response.usage.map { TokenUsage(input: $0.prompt_tokens, output: $0.completion_tokens, total: $0.total_tokens) }

        let choice = response.choices.first
        let stop: GenerationStop? = choice?.finish_reason.map { .init(code: $0, message: nil) }
        var contents: [MessageContent] = []
        if let content = choice?.message.content {
            let text = TextGeneratedContent(delta: nil, content: content, annotations: [])
            contents.append(.text(text))
        } else if let refusal = choice?.message.refusal {
            let refusal = TextRefusalGeneratedContent(content: refusal)
            contents.append(.refusal(refusal))
        }

        let item = MessageItem(id: response.id, index: 0, content: contents)
        self.init(id: response.id, context: context, model: response.model, items: [.message(item)], usage: usage, stop: stop, error: nil)
    }
}
