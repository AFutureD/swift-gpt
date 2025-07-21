public struct GenerationError: Codable, Sendable {
    public let code: String?
    public let message: String?
}

public struct GenerationStop: Codable, Sendable {
    public let code: String?
    public let message: String?
}

public struct ModelResponse: Codable, Sendable {
    let id: String?

    let items: [ResponseItem]

    let usage: TokenUsage?

    let stop: GenerationStop?
    let error: GenerationError?
}

public enum ModelStreamResponse: Codable, Sendable {
    // ERROR
    case error(GenerationError?)

    // Response
    case create
    case completed(ModelResponse)

    // Item
    case itemAdded(ResponseItem)
    case itemDone(ResponseItem)

    // Item.Content
    case contentAdded(ResponseContent)
    case contentDelta(ResponseContent) // any PartialUpdatable & GeneratedItem
    case contentDone(ResponseContent)
}

public struct TokenUsage: Codable, Sendable {
    let input: Int?
    let output: Int?
    let total: Int?
}
