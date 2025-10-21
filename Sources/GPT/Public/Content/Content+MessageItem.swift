//
//  Content+MessageItem.swift
//  swift-gpt
//
//  Created by AFuture on 2025/7/21.
//

/// An enumeration of the types of content that can be included in a message item.
public enum MessageContent: Sendable {
    /// Text-based content.
    case text(TextGeneratedContent)
    /// A refusal to provide content.
    case refusal(TextRefusalGeneratedContent)
}

public extension MessageContent {
    var text: TextGeneratedContent? {
        guard case .text(let value) = self else {
            return nil
        }
        return value
    }

    var refusal: TextRefusalGeneratedContent? {
        guard case .refusal(let value) = self else {
            return nil
        }
        return value
    }
}

extension MessageContent: Codable {
    enum CodingKeys: String, CodingKey {
        case type
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ContentType.self, forKey: .type)
        switch type {
        case .generatedText:
            self = try .text(.init(from: decoder))
        case .generatedTextRefusal:
            self = try .refusal(.init(from: decoder))
        default:
            throw DecodingError.typeMismatch(MessageItem.self, .init(codingPath: [], debugDescription: "Only Support 'MessageItem'"))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text(let value):
            try container.encode(value)
        case .refusal(let value):
            try container.encode(value)
        }
    }
}

public extension ContentType {
    /// The content type for a message item.
    static let generatedMessage = ContentType(rawValue: "response.message")
}

/// A single message item in a response, which can contain multiple content blocks.
public struct MessageItem: Identifiable, Sendable, Codable {
    public let id: String
    public let type: ContentType = .generatedMessage
    public let index: Int?

    /// The content of the message, which can be text or a refusal.
    public let content: [MessageContent]?

    enum CodingKeys: CodingKey {
        case id
        case type
        case index
        case content
    }

    public init(id: String, index: Int?, content: [MessageContent]?) {
        self.id = id
        self.index = index
        self.content = content
    }
}
