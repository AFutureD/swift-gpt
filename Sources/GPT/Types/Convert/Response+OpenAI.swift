import AsyncAlgorithms
import LazyKit
import SynchronizationKit

extension OpenAIModelReponseContext {
    func convert(idx: Int) -> (any GeneratedItem)? {
        switch self {
        case .output(let output):
            let contents = output.content.map {
                $0.convertToGenratedItem()
            }
            return MessageItem(id: output.id, index: idx, content: contents)
        default:
            return nil
        }
    }
}

extension Collection where Element == OpenAIModelReponseContext {
    func convert() -> [any GeneratedItem] {
        return self.enumerated().compactMap { index, context in
            context.convert(idx: index)
        }
    }
}

extension ModelStreamResponse {
    init?(_ event: OpenAIModelStreamResponse) {
        switch event {
        case .response_created(_):
            self = .create  // Pass id
        case .response_completed(let completed):
            let usage = TokenUsage(
                input: completed.response.usage?.input_tokens,
                output: completed.response.usage?.output_tokens,
                total: completed.response.usage?.total_tokens
            )
            let items = completed.response.output.convert()
            let response = ModelResponse(id: completed.response.id, items: items, usage: usage)
            self = .completed(response)
        case .response_incomplete(_):
            self = .error  // TODO: throw incomplete info as error
        case .error(_):
            self = .error
        case .response_output_item_added(let itemAdded):
            if let item = itemAdded.item.convert(idx: itemAdded.output_index) {
                self = .itemDone(item)
            } else {
                return nil
            }
        case .response_output_item_done(let itemDone):
            if let item = itemDone.item.convert(idx: itemDone.output_index) {
                self = .itemDone(item)
            } else {
                return nil
            }

        case .response_content_part_added(let partAdded):
            let content = partAdded.part.convertToGenratedItem()
            self = .contentAdded(content)
        case .response_content_part_done(let partDone):
            let content = partDone.part.convertToGenratedItem()
            self = .contentDone(content)
        case .response_output_text_delta(let textDelta):
            let content = TextContent(delta: textDelta.delta, content: nil, annotations: [])
            self = .contentDelta(content)
        default:
            return nil
        }
    }
}

extension OpenAIModelReponseContextOutputContent {
    func convertToGenratedItem() -> any GeneratedItem {
        switch self {
        case .text(let text):
            TextContent(delta: nil, content: text.text, annotations: [])  // TODO: support annotations
        case .refusal(let refusal):
            TextRefusalContent(content: refusal.refusal)
        }
    }
}

struct OpenAIChatCompletionStreamResponseAggregater: Sendable {

    private let didSendCreate: LazyLockedValue<Bool> = .init(false)
    private let hasEmittedFirstContent: LazyLockedValue<Bool> = .init(false)
    private let currentContent: LazyLockedValue<(any GeneratedItem)?> = .init(nil)

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
            result.append(.create)
        }

        guard let choice = event.choices.first else {
            let usage = TokenUsage(
                input: event.usage?.prompt_tokens,
                output: event.usage?.completion_tokens,
                total: event.usage?.total_tokens
            )
            let item = currentItem(id: event.id)

            let response = ModelResponse(id: event.id, items: [item], usage: usage)
            result.append(.completed(response))
            return result
        }

        if let finish = choice.finish_reason {
            switch finish {
            case "stop":
                let item = currentItem(id: event.id)
                result.append(.itemDone(item))

            case "length":
                result.append(.error)

            case "content_filter":
                result.append(.error)

            case "tool_calls":
                result.append(.error)

            default:
                break
            }
        }

        if choice.delta.role != nil {
            let textContent = TextContent(delta: nil, content: choice.delta.content, annotations: [])
            currentContent.withLock { $0 = textContent }

            let messageItem = MessageItem(id: event.id, index: 0, content: nil)
            result.append(.contentAdded(messageItem))
        }

        if let delta = choice.delta.content {
            currentContent.withLock {
                let previous = ($0 as? TextContent)?.content
                $0 = TextContent(delta: nil, content: (previous ?? "") + delta, annotations: [])
            }
            result.append(.contentDelta(TextContent(delta: delta, content: nil, annotations: [])))
        }

        if let refusal = choice.delta.refusal {
            let content = TextRefusalContent(content: refusal)
            currentContent.withLock { $0 = content }
            result.append(.contentDone(content))
        }

        return result
    }

    func currentItem(id: String) -> any GeneratedItem {
        let text = currentContent.withLock { $0 }
        let content: [any GeneratedItem] = text.flatMap { [$0] } ?? []

        let messageItem = MessageItem(id: id, index: 0, content: content)
        return messageItem
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
