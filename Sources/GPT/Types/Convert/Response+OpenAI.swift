extension ModelStreamResponse {
    init?(_ event: OpenAIModelStreamResponse) {
        switch event {
        case .response_created(_):
            self = .create  // Pass id
        case .response_completed(let completed):
            self = .completed(responseId: completed.response.id, usage: nil)
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
                self = .itemAdded(MessageItem(id: output.id, index: itemDone.output_index, content: contents))
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
            self = .contentDone(content)
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


extension ModelStreamResponse {
    init?(_ event: OpenAIChatCompletionStreamResponse) {
        return nil
    }
}
