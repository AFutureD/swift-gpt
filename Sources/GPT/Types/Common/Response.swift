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
    case contentDelta(any PartialUpdatable & GeneratedItem)
    case contentDone(any GeneratedItem)
}

struct TokenUsage {}

// MARK: Content - Text

extension GeneratedContentType {
    static let text = GeneratedContentType(rawValue: "response.message.text")
}

struct TextContent: PartialUpdatable, GeneratedItem {
    // TODO: Support content index
    
    let type: GeneratedContentType = .text

    let delta: String?

    let content: String?
    let annotations: [Annotation]
}

// MARK: Content - Text Annotation

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

// MARK: Content - Refusal

extension GeneratedContentType {
    static let textRefusal = GeneratedContentType(rawValue: "response.message.text.refusal")
}

struct TextRefusalContent: GeneratedItem {

    let type: GeneratedContentType = .textRefusal

    let content: String?
}

// MARK: Message

extension GeneratedContentType {
    static let message = GeneratedContentType(rawValue: "response.message")
}

struct MessageItem: Identifiable, GeneratedSortableItem {
    let id: String
    let type: GeneratedContentType = .message
    let index: Int?

    // Text Or TextRefusal
    let content: [any GeneratedItem]?
}
