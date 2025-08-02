
import Algorithms
import AsyncAlgorithms
import LazyKit
import SynchronizationKit




extension OpenAIChatCompletionRequestMessageContentPart {
    init?(item: OpenAIModelReponseRequestInputItemMessageContentItem) {
        switch item {
        case .text(let text):
            self = .text(.init(text: text.text))
        case .file(let file):
            self = .file(
                .init(file: .init(fileId: file.fileID, filename: file.filename, fileData: file.fileData)))
        default:
            return nil
        }
    }
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

extension OpenAIChatCompletionRequestMessage {
    init?(_ item: OpenAIModelReponseRequestInputItem) {
        switch item {
        case .message(let message):
            self = OpenAIChatCompletionRequestMessage(message)
        case .output(let output):
            guard let message = OpenAIChatCompletionRequestMessage(output) else {
                return nil
            }
            self = message
        case .reference(_):
            return nil
        }
    }
}

extension OpenAIChatCompletionRequestMessageContentPart {
    init?(_ input: Prompt.Input) {
        switch input {
        case .text(let text):
            self = .text(.init(text: text.content))
        case .file(let file):
            self = .file(.init(file: .init(fileId: file.id, filename: file.filename, fileData: file.content)))
        }
    }
}

extension OpenAIChatCompletionRequest {
    init(_ prompt: Prompt, model: String, stream: Bool) {

        let messages: [OpenAIChatCompletionRequestMessage] = prompt.inputs.chunked(
            on: \.content.role
        ).compactMap { role, inputs in
            let parts = inputs.compactMap {
                OpenAIChatCompletionRequestMessageContentPart($0)
            }
            switch role {
            case .system:
                return .system(.init(content: .parts(parts), name: nil))
            case .assistant:
                return .assistant(.init(audio: nil, content: .parts(parts), name: nil, refusal: nil, tool_calls: nil))
            case .user:
                return .user(.init(content: .parts(parts), name: nil))
            case .developer:
                return .developer(.init(content: .parts(parts), name: nil))
            default:
                return nil
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
            stream: stream,
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

struct OpenAIChatCompletionStreamResponseAggregater: Sendable {

    private let didSendCreate: LazyLockedValue<Bool> = .init(false)
    private let didSendItemCreate: LazyLockedValue<Bool> = .init(false)
    
    private let hasEmittedFirstContent: LazyLockedValue<Bool> = .init(false)
    private let currentContent: LazyLockedValue<ResponseContent?> = .init(nil)
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
        
        if event.choices.first == nil || event.usage != nil {
            let usage = TokenUsage(
                input: event.usage?.prompt_tokens,
                output: event.usage?.completion_tokens,
                total: event.usage?.total_tokens
            )
            let item = currentItem(id: event.id)
            let stop = stopReason.withLock { $0 }
            
            let response = ModelResponse(id: event.id, items: [item], usage: usage, stop: stop, error: nil)
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
            
            let textContent: ResponseContent = .text(TextContent(delta: nil, content: choice.delta.content, annotations: []))
            currentContent.withLock { $0 = textContent }
            result.append(.contentAdded(.init(event: .contentAdded, data: textContent)))
        }
        
        if let delta = choice.delta.content {
            currentContent.withLock {
                let previous = $0?.text?.content
                $0 = .text(TextContent(delta: nil, content: (previous ?? "") + delta, annotations: []))
            }
            result.append(.contentDelta(.init(event: .contentDelta, data: .text(TextContent(delta: delta, content: nil, annotations: [])))))
        }

        if let refusal = choice.delta.refusal {
            let content: ResponseContent = .refusal(TextRefusalContent(content: refusal))
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

    func currentItem(id: String) -> ResponseItem {
        let content = currentContent.withLock { $0 }
        let contents: [ResponseContent] = content.flatMap { [$0] } ?? []

        let messageItem = MessageItem(id: id, index: 0, content: contents)
        return .message(messageItem)
    }
}

public struct OpenAIChatCompletionStreamResponseAsyncAggregater<Base: AsyncSequence & Sendable>: Sendable, AsyncSequence
where Base.Element == OpenAIChatCompletionStreamResponse {

    let base: Base
    public init(base: Base) {
        self.base = base
    }

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
