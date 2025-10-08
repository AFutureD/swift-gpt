
import Algorithms
import AsyncAlgorithms
import LazyKit
import SynchronizationKit

extension OpenAIChatCompletionRequestMessage {
    init?(_ input: Prompt.Input) {
        switch input {
        case let .text(text):
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
        case let .file(file):
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
        case let .message(message):
            let refusal: String? = message.content?.map {
                if case let .refusal(refusal) = $0 {
                    return refusal.content
                }
                return nil
            }.first ?? nil

            let parts: [OpenAIChatCompletionRequestMessageContentPart] = message.content?.compactMap { content in
                switch content {
                case let .text(text):
                    if let text = text.content {
                        return OpenAIChatCompletionRequestMessageContentPart.text(OpenAIChatCompletionRequestMessageContentTextPart(text: text))
                    }
                    return nil
                case let .refusal(refusal):
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
        var messages: [OpenAIChatCompletionRequestMessage] = []

        if history.items.isEmpty {
            switch prompt.instructions {
            case let .text(text):
                messages.append(.system(.init(content: .text(text), name: nil)))
            case let .inputs(inputs):
                messages.append(contentsOf: inputs.compactMap { OpenAIChatCompletionRequestMessage($0) })
            case nil:
                break
            }
        }

        let items = history.items
        for item in items {
            switch item {
            case let .input(input):
                let message = OpenAIChatCompletionRequestMessage(input)
                if let message {
                    messages.append(message)
                }
            case let .generated(generated):
                let message = OpenAIChatCompletionRequestMessage(generated)
                if let message {
                    messages.append(message)
                }
            }
        }

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
            maxCompletionTokens: prompt.generation?.maxTokens,
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
            store: prompt.generation?.store,
            stream: stream,
            streamOptions: stream ? .init(includeUsage: true) : nil,
            temperature: prompt.generation?.temperature,
            toolChoice: nil,
            tools: nil,
            topLogprobs: nil,
            topP: prompt.generation?.topP,
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
