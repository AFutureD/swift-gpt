import LazyKit

/// The item that represents a turn in the conversation, which can be either user input or a generated response.
public enum ConversationItem: Sendable {
    case input(Prompt.Input)
    case generated(GeneratedItem)
}

extension ConversationItem: Codable {
    enum CodingKeys: String, CodingKey {
        case type
    }   

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ContentType.self, forKey: .type)
        
        switch type {
        case .inputText, .inputFile:
            self = try .input(.init(from: decoder))
        case .generatedMessage:
            self = try .generated(.init(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown ConversationItem type")
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .input(let inputItem):
            try container.encode(inputItem)
        case .generated(let generatedItem):
            try container.encode(generatedItem)
        }
    }
}


/// The Conversation struct represents a user conversation, consisting of multiple turns.
public struct Conversation: Sendable, Codable {
    public var id: String?
    
    public var items: [ConversationItem]

    public init(id: String? = nil, items: [ConversationItem] = []) {
        self.id = id
        self.items = items
    }
}