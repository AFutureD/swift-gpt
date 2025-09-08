extension ModelResponse {
    public var item: GeneratedItem? {
        items.first
    }

    public var message: MessageItem? {
        item?.message
    }
}

extension MessageItem {
    public var refusalContent: TextRefusalGeneratedContent? {
        content?.compactMap {
            $0.refusal
        }.first
    }

    public var textContents: [TextGeneratedContent]? {
        content?.compactMap {
            if case let .text(text) = $0 {
                return text
            }
            return nil
        }
    }

    public var textContent: TextGeneratedContent? {
        textContents?.first
    }

    public var text: String? {
        textContent?.content
    }
}