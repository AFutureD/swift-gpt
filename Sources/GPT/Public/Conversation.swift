import LazyKit


public enum ConversationItem: Sendable {
    case input(Prompt.Input)
    case generated(GeneratedItem)
}

extension ConversationItem: Codable {
    enum CodingKeys: String, CodingKey {
        case type
    }   

    public init(from decoder: Decoder) throws {
        todo("ConversationItem Need to implement decode")
    }

    public func encode(to encoder: any Encoder) throws {
        todo("ConversationItem Need to implement encode")
    }
}

public struct Conversation: Sendable, Codable {
    public var id: String?
    
    public var items: [ConversationItem]

    init(id: String? = nil, items: [ConversationItem] = []) {
        self.id = id
        self.items = items
    }
}