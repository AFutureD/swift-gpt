extension ModelStreamResponse {
    init?(_ event: OpenAIModelStreamResponse) {
        switch event {
        case .response_created(_):
            self = .create  // Pass id
        case .response_completed(let completed):
            self = .completed(responseId: completed.response.id, usage: nil)
        case .response_incomplete(let incompleted):
            self = .error  // TODO: throw incomplete info as error
        case .error(let error):
            self = .error
        case .response_output_item_added(let itemAdded):
            switch itemAdded.item {
            case .output(let output):
                self = .itemAdded(MessageItem(id: output.id, content: nil))
            default:
                return nil
            }
        case .response_output_item_done(let itemDone):
            switch itemDone.item {
            case .output(let output):
                let contents: [any GeneratedItem] = output.content.map {
                    switch $0 {
                    case .text(let text):
                        TextContent(delta: nil, content: text.text, annotations: [])  // TODO: support annotations
                    case .refusal(let refusal):
                        TextRefusalContent(content: refusal.refusal)
                    }
                }
                self = .itemAdded(MessageItem(id: output.id, content: contents))
            default:
                return nil
            }
        case .response_content_part_added(let partAdded):
            let content: any GeneratedItem =
                switch partAdded.part {
                case .text(let text):
                    TextContent(delta: nil, content: text.text, annotations: [])
                case .refusal(let refusal):
                    TextRefusalContent(content: refusal.refusal)
                }
            self = .contentAdded(content)
        case .response_content_part_done(let partDone):
            let content: any GeneratedItem =
                switch partDone.part {
                case .text(let text):
                    TextContent(delta: nil, content: text.text, annotations: [])
                case .refusal(let refusal):
                    TextRefusalContent(content: refusal.refusal)
                }
            self = .contentDone(content)
        case .response_output_text_delta(let textDelta):
            let content = TextContent(delta: textDelta.delta, content: nil, annotations: [])
            self = .contentDone(content)
        default:
            return nil
        }
    }
}

extension ModelStreamResponse {
    init?(_ event: OpenAIChatCompletionStreamResponse) {
        return nil
    }
}
