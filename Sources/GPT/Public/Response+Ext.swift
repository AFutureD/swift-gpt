public extension ModelResponse {
    var item: GeneratedItem? {
        items.first
    }

    var message: MessageItem? {
        item?.message
    }
}

public extension MessageItem {
    var refusalContent: TextRefusalGeneratedContent? {
        content?.compactMap {
            $0.refusal
        }.first
    }

    var textContents: [TextGeneratedContent]? {
        content?.compactMap {
            if case .text(let text) = $0 {
                return text
            }
            return nil
        }
    }

    var textContent: TextGeneratedContent? {
        textContents?.first
    }

    var text: String? {
        textContent?.content
    }
}
