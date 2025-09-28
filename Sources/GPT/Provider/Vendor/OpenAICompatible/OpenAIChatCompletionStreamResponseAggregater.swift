//
//  OpenAIChatCompletionStreamResponseAggregater.swift
//  swift-gpt
//
//  Created by Huanan on 2025/9/24.
//

import Algorithms
import AsyncAlgorithms
import LazyKit
import SynchronizationKit

extension AsyncSequence where Self: Sendable, Self.Element == OpenAIChatCompletionStreamResponse {
    func aggregateToModelStremResponse() -> OpenAIChatCompletionStreamResponseAsyncAggregater<Self> {
        OpenAIChatCompletionStreamResponseAsyncAggregater<Self>(base: self)
    }
}


public struct OpenAIChatCompletionStreamResponseAsyncAggregater<Base>: Sendable, AsyncSequence
    where Base: AsyncSequence & Sendable, Base.Element == OpenAIChatCompletionStreamResponse
{

    let base: Base
    public init(base: Base) {
        self.base = base
    }
    
    public func makeAsyncIterator() -> Iterator {
        return Iterator(iterator: base.makeAsyncIterator())
    }
}

extension OpenAIChatCompletionStreamResponseAsyncAggregater {
    public struct Iterator: AsyncIteratorProtocol {
        enum State {
            case create(Base.AsyncIterator)
            case itemAdded(Base.AsyncIterator, event: Base.Element)
            case contentAdded(Base.AsyncIterator, event: Base.Element)
            case contentDelta(Base.AsyncIterator, current: MessageContent)
            case contentDone(MessageContent)
            case itemDone(MessageContent?)
            case completed(GeneratedItem?)
            case finished
        }
        
        init(iterator: Base.AsyncIterator) {
            self.state = .create(iterator)
        }
        
        private var state: State
        private var stopReason: GenerationStop?
        private var usage: TokenUsage?
        private var id: String?
        private var model: String?

        public mutating func next() async throws -> ModelStreamResponse? {
            switch state {
            case .create(var iterator):
                if let event = try await iterator.next() {
                    state = .itemAdded(iterator, event: event)
                    id = event.id
                    model = event.model
                } else {
                    state = .completed(nil)
                }
                return .create(.init(event: .create, data: .init(id: id, model: model, items: [], usage: nil, stop: nil, error: nil)))
                
            case .itemAdded(let iterator, let event):
                state = .contentAdded(iterator, event: event)
                let messageItem = MessageItem(id: event.id, index: 0, content: nil)
                return .itemAdded(.init(event: .itemAdded, data: .message(messageItem)))
                
            case .contentAdded(let iterator, event: let event):
                let (state, content) = generate(event, iterator: iterator, current: nil)
                self.state = state
                return .contentAdded(.init(event: .contentAdded, data: content))
                
            case .contentDelta(var iterator, current: let current):
                if let event = try await iterator.next() {
                    let (state, content) = generate(event, iterator: iterator, current: current)
                    self.state = state
                    return .contentDelta(.init(event: .contentDelta, data: content))
                } else {
                    state = .contentDone(current)
                    return .contentDelta(.init(event: .contentDelta, data: current))
                }
                
            case .contentDone(let current):
                state = .itemDone(current)
                return .contentDone(.init(event: .contentDone, data: current))
                
            case .itemDone(let current):
                let item = MessageItem(id: "", index: nil, content: current.flatMap { [$0] } ?? [])
                state = .completed(.message(item))
                return .itemDone(.init(event: .itemDone, data: GeneratedItem.message(item)))
                
            case .completed(let item):
                state = .finished
                let items = item.flatMap { [$0] } ?? []
                return .completed(.init(event: .completed, data: .init(id: id, model: model, items: items, usage: usage, stop: stopReason, error: nil)))

            case .finished:
                return nil
                
            }
        }
        
        mutating func generate(
            _ event: OpenAIChatCompletionStreamResponse,
            iterator: Base.AsyncIterator,
            current: MessageContent?
        ) -> (State, MessageContent) {
            if let usage = event.usage, usage.total_tokens > 0 {
                self.usage = TokenUsage(
                    input: usage.prompt_tokens,
                    output: usage.completion_tokens,
                    total: usage.total_tokens
                )
            }

            guard let current else {
                let delta = event.choices.first?.delta.content
                let content = TextGeneratedContent(delta: delta, content: delta, annotations: [])
                return (.contentDelta(iterator, current: .text(content)), .text(content))
            }
            
            guard let choice = event.choices.first else {
                return (.contentDone(current) , current)
            }

            if let refusal = choice.delta.refusal {
                let content: MessageContent = .refusal(TextRefusalGeneratedContent(content: refusal))
                return (.contentDone(content) , content)
            }
            
            let delta = choice.delta.content
            
            let previous = current.text?.content
            let new = MessageContent.text(TextGeneratedContent(delta: delta,
                                                               content: (previous ?? "") + (delta ?? ""),
                                                               annotations: []))
            
            if let finish = choice.finish_reason {
                stopReason = .init(code: finish, message: nil)
            }
            
            return (.contentDelta(iterator, current: new), new)
        }
        
    }
}
