import SynchronizationKit
import AsyncAlgorithms
import LazyKit

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
            self = .completed(responseId: completed.response.id, usage: usage)
        case .response_incomplete(_):
            self = .error  // TODO: throw incomplete info as error
        case .error(_):
            self = .error
        case .response_output_item_added(let itemAdded):
            switch itemAdded.item {
            case .output(let output):
                self = .itemAdded(MessageItem(id: output.id, index: itemAdded.output_index, content: nil))
            default:
                return nil
            }
        case .response_output_item_done(let itemDone):
            switch itemDone.item {
            case .output(let output):
                let contents = output.content.map {
                    $0.convertToGenratedItem()
                }
                self = .itemDone(MessageItem(id: output.id, index: itemDone.output_index, content: contents))
            default:
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
    private let currentTextContent: LazyLockedValue<(any GeneratedItem)?> = .init(nil)
    
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
            result.append(.completed(responseId: event.id,usage: usage))
            return result
        }
        
        if let finish = choice.finish_reason {
            switch finish {
            case "stop":
                let text = currentTextContent.withLock { $0 }
                let content: [any GeneratedItem] = text.flatMap { [$0] } ?? []
                
                let messageItem = MessageItem(id: event.id, index: 0, content: content)
                result.append(.itemDone(messageItem))
                
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
            currentTextContent.withLock { $0 = textContent }
            
            let messageItem = MessageItem(id: event.id, index: 0, content: nil)
            result.append(.contentAdded(messageItem))
        }
        
        if let delta = choice.delta.content {
            currentTextContent.withLock {
                let previous = ($0 as? TextContent)?.content
                $0 = TextContent(delta: nil, content: (previous ?? "") + delta, annotations: [])
            }
            result.append(.contentDelta(TextContent(delta: delta, content: nil, annotations: [])))
        }
        
        if let Refusal = choice.delta.refusal {
            let content = TextRefusalContent(content: Refusal)
            currentTextContent.withLock { $0 = content }
            result.append(.contentDone(content))
        }
        
        return result
    }
    
}

public struct OpenAIChatCompletionStreamResponseAsyncAggregater<Base: AsyncSequence & Sendable>: Sendable, AsyncSequence where Base.Element == OpenAIChatCompletionStreamResponse {
    
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
