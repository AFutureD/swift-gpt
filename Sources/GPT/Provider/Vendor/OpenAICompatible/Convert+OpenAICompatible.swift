
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
                if case let .refusal(refusal) =  $0 {
                    return refusal.content
                }
                return nil
            }.first ?? nil

            let parts: [OpenAIChatCompletionRequestMessageContentPart] = message.content?.compactMap { content in
                switch content {
                case .text(let text):
                    if let text = text.content {
                        return OpenAIChatCompletionRequestMessageContentPart.text(OpenAIChatCompletionRequestMessageContentTextPart.init(text: text))
                    }
                    return nil
                case .refusal(let refusal):
                    if let refusal = refusal.content {
                        return OpenAIChatCompletionRequestMessageContentPart.refusal(OpenAIChatCompletionRequestMessageContentRefusalPart.init(refusal: refusal))
                    }
                    return nil
                }
            } ?? []

            self = .assistant(.init(audio: nil, content: .parts(parts), name: nil, refusal: refusal, tool_calls: nil))
        }
        return nil
    }
}


extension OpenAIChatCompletionRequest {
    init(_ prompt: Prompt, conversation: Conversation, model: String, stream: Bool) {
        var messages: [OpenAIChatCompletionRequestMessage] = []
        
        if let instruction = prompt.instructions {
            messages.append(.system(.init(content: .text(instruction), name: nil)))
        }

        let items = conversation.items
        for item in items {
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

        self.init(
            messages: messages,
            model: model,
            audio: nil,
            frequencyPenalty: nil,
            logitBias: nil,
            logprobs: nil,
            maxCompletionTokens: prompt.maxTokens,
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
            stream: stream,
            streamOptions: stream ? .init(includeUsage: true) : nil,
            temperature: prompt.temperature,
            toolChoice: nil,
            tools: nil,
            topLogprobs: nil,
            topP: prompt.topP,
            user: nil,
            webSearchOptions: nil
        )
    }
}

struct OpenAIChatCompletionStreamResponseAggregater: Sendable {

    private let didSendCreate: LazyLockedValue<Bool> = .init(false)
    private let didSendItemCreate: LazyLockedValue<Bool> = .init(false)
    
    private let hasEmittedFirstContent: LazyLockedValue<Bool> = .init(false)
    private let currentContent: LazyLockedValue<MessageContent?> = .init(nil)
    private let stopReason: LazyLockedValue<GenerationStop?> = .init(nil)

    func handle(_ event: OpenAIChatCompletionStreamResponse) -> [ModelStreamResponse] {
        var result: [ModelStreamResponse] = []

        let sent = self.didSendCreate.withLock { sent in
            if sent {
                return true
            } else {
                sent = true
                return false
            }
        }

        if !sent {
            result.append(.create(.init(event: .create, data: nil)))
        }
        
        if event.choices.first == nil || (event.usage != nil && event.usage?.total_tokens != 0) {
            let usage = TokenUsage(
                input: event.usage?.prompt_tokens,
                output: event.usage?.completion_tokens,
                total: event.usage?.total_tokens
            )
            let item = currentItem(id: event.id)
            let stop = stopReason.withLock { $0 }
            
            let response = ModelResponse(id: event.id, model: event.model, items: [item], usage: usage, stop: stop, error: nil)
            result.append(.completed(.init(event: .completed, data: response)))
            return result
        }
        
        let choice = event.choices.first!

        let itemAddSent = self.didSendItemCreate.withLock { sent in
            if sent {
                return true
            } else {
                sent = true
                return false
            }
        }
        
        if !itemAddSent, choice.delta.role != nil {
            let messageItem = MessageItem(id: event.id, index: 0, content: nil)
            result.append(.itemAdded(.init(event: .itemAdded, data: .message(messageItem))))
            
            let textContent: MessageContent = .text(TextGeneratedContent(delta: nil, content: "", annotations: []))
            currentContent.withLock { $0 = textContent }
            result.append(.contentAdded(.init(event: .contentAdded, data: textContent)))
        }
        
        if let delta = choice.delta.content {
            currentContent.withLock {
                let previous = $0?.text?.content
                $0 = .text(TextGeneratedContent(delta: nil, content: (previous ?? "") + delta, annotations: []))
            }
            result.append(.contentDelta(.init(event: .contentDelta, data: .text(TextGeneratedContent(delta: delta, content: nil, annotations: [])))))
        }

        if let refusal = choice.delta.refusal {
            let content: MessageContent = .refusal(TextRefusalGeneratedContent(content: refusal))
            currentContent.withLock { $0 = content }
            result.append(.contentDone(.init(event: .contentDone, data: content)))
        }

        if let finish = choice.finish_reason {
            switch finish {
            case "stop":
                let item = currentItem(id: event.id)
                result.append(.itemDone(.init(event: .itemDone, data: item)))
                
            default:
                stopReason.withLock {
                    $0 = .init(code: finish, message: nil)
                }
            }
        }
        
        return result
    }

    func currentItem(id: String) -> GeneratedItem {
        let content = currentContent.withLock { $0 }
        let contents: [MessageContent] = content.flatMap { [$0] } ?? []

        let messageItem = MessageItem(id: id, index: 0, content: contents)
        return .message(messageItem)
    }
}

public struct OpenAIChatCompletionStreamResponseAsyncAggregater<Base: AsyncSequence & Sendable>: Sendable, AsyncSequence where Base.Element == OpenAIChatCompletionStreamResponse {

    let base: Base
    public init(base: Base) {
        self.base = base
    }
    
    // TODO: rewrite the stream with custom iterator,
    //       manually send created and finished event.
    public func makeAsyncIterator() -> AnyAsyncSequence<ModelStreamResponse>.AsyncIterator {
        let aggregater = OpenAIChatCompletionStreamResponseAggregater()

        return base.flatMap {
            aggregater.handle($0).async
        }.eraseToAnyAsyncSequence().makeAsyncIterator()
    }
}

extension AsyncSequence where Self: Sendable, Self.Element == OpenAIChatCompletionStreamResponse {
    func aggregateToModelStremResponse() -> OpenAIChatCompletionStreamResponseAsyncAggregater<Self> {
        OpenAIChatCompletionStreamResponseAsyncAggregater<Self>(base: self)
    }
}

extension ModelResponse {
    init(_ response: OpenAIChatCompletionResponse) {
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
        self.init(id: response.id, model: response.model, items: [.message(item)], usage: usage, stop: stop, error: nil)
    }
}
