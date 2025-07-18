public struct GenerationError: Sendable {
    public let code: String?
    public let message: String?
}

public struct GenerationStop: Sendable {
    public let code: String?
    public let message: String?
}

public struct ModelResponse: Sendable {
    let id: String?

    let items: [any GeneratedItem]

    let usage: TokenUsage?

    let stop: GenerationStop?
    let error: GenerationError?
}

public enum ModelStreamResponse: Sendable {
    // ERROR
    case error(GenerationError?)

    // Response
    case create
    case completed(ModelResponse)

    // Item
    case itemAdded(any GeneratedItem)
    case itemDone(any GeneratedItem)

    // Item.Content
    case contentAdded(any GeneratedItem)
    case contentDelta(any PartialUpdatable & GeneratedItem)
    case contentDone(any GeneratedItem)
}

public struct TokenUsage: Sendable {
    let input: Int?
    let output: Int?
    let total: Int?
}

// MARK: Content - Text

extension GeneratedContentType {
    public static let text = GeneratedContentType(rawValue: "response.message.text")
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
