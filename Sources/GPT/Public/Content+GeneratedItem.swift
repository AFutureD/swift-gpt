// MARK: ResponseItem

/// An enumeration of the types of items that can be included in a response.
/// 
/// All sub item SHOULD be identifiable.
public enum GeneratedItem: Sendable {
    /// A message item, containing the main content of the response.
    case message(MessageItem)
}

extension GeneratedItem {
    public var message: MessageItem? {
        guard case let .message(value) = self else {
            return nil
        }
        return value
    }
}

// MARK: ResponseItem + Codable

extension GeneratedItem: Codable {
    enum CodingKeys: String, CodingKey {
        case type
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(GeneratedContentType.self, forKey: .type)
        switch type {
        case .generatedMessage:
            self = try .message(.init(from: decoder))
        default:
            throw DecodingError.typeMismatch(MessageItem.self, .init(codingPath: [], debugDescription: "Only Support 'MessageItem'"))
        }
    }
    
    /// Encodes the generated item into the given `Encoder` as a single value.
    /// 
    /// The associated `MessageItem` for the `.message` case is encoded directly into a single-value container; no separate type tag is emitted.
    /// - Parameters:
    ///   - encoder: The encoder to write the encoded representation to.
    /// - Throws: Any error thrown while encoding the associated `MessageItem`.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .message(let messageItem):
            try container.encode(messageItem)
        }
    }
}