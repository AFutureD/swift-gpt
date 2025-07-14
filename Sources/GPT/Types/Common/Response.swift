enum ModelStreamResponse: Sendable {
    // Start
    case create

    // End
    case completed(responseId: String, usage: TokenUsage?)
    case error

    // Item
    case itemAdded(any GeneratedItem)
    case itemDone(any GeneratedItem)

    // Item.Content
    case contentAdded(any GeneratedItem)
    case contentDelta(any PartialUpdatableItem)
    case contentDone(any GeneratedItem)
}

struct TokenUsage {}

// MARK: Text

extension GeneratedContentType {
    static let text = GeneratedContentType(rawValue: "response.message.text")
}

struct TextContent: PartialUpdatableItem {
    let id: String
    let type: GeneratedContentType = .text

    let delta: String?

    let content: String?
    let annotations: [Annotation]
}

// MARK: Text Annotation

extension GeneratedContentType {
    static let textAnnotation = GeneratedContentType(rawValue: "response.message.text.annotation")
}

extension TextContent {
    struct Annotation: GeneratedItem {
        let id: String
        let type: GeneratedContentType = .textAnnotation

        let content: String?
    }
}

// MARK: Refusal

extension GeneratedContentType {
    static let textRefusal = GeneratedContentType(rawValue: "response.message.text.refusal")
}

struct TextRefusalContent: GeneratedItem {
    let id: String
    let type: GeneratedContentType = .textRefusal

    let content: String?
}

// MARK: Message

extension GeneratedContentType {
    static let message = GeneratedContentType(rawValue: "response.message")
}

struct MessageItem: GeneratedItem {
    let id: String
    let type: GeneratedContentType = .message

    // Text Or TextRefusal
    let content: [any GeneratedItem]?
}
