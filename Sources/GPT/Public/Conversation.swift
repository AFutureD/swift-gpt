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

extension Conversation {
    /// Identifies a previous response for continuing a conversation.
    ///
    /// Before reuse, verify that the selected provider configuration can access this response.
    /// Matching the provider type and name alone does not guarantee access.
    public struct ResponseReference: Sendable, Codable {
        /// The originating provider configuration's name, if available.
        public let name: String?

        /// The originating provider's type.
        public let provider: LLMProviderType
        
        /// The provider's response ID, used as `previous_response_id` in the Responses API.
        ///
        /// Use `OpenAIModelReponse.id`, exposed as `ModelResponse.id`.
        /// `Conversation.id` identifies the business conversation and is separate from this ID.
        public let id: String
    }
}

/// The Conversation struct represents a user conversation, consisting of multiple turns.
public struct Conversation: Sendable, Codable {
    /// The identifier of the conversation in the business layer.
    ///
    /// It is defined and managed by the caller.
    /// It does not correspond to any session ID or response ID of the providers.
    public var id: String?

    public var items: [ConversationItem]
    
    /// The latest provider response reference for continuing this conversation.
    ///
    /// Update this after accepting a response into the conversation.
    /// A `nil` value means no response reference is available; local history may still exist in `items`.
    /// Before reuse, verify that the selected provider configuration can access the response.
    public var lastReference: ResponseReference?

    public init(id: String? = nil, items: [ConversationItem] = []) {
        self.id = id
        self.items = items
    }
}
