//
//  Content.swift
//  swift-gpt
//
//  Created by AFuture on 2025/7/21.
//

// MARK: ResponseItem

public enum ResponseItem: Sendable {
    case message(MessageItem)
}

// MARK: ResponseItem + Codable

extension ResponseItem: Codable {
    enum CodingKeys: String, CodingKey {
        case type
    }
  
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(GeneratedContentType.self, forKey: .type)
        switch type {
        case .message:
            self = try .message(.init(from: decoder))
        default:
            throw DecodingError.typeMismatch(MessageItem.self, .init(codingPath: [], debugDescription: "Only Support 'MessageItem'"))
        }
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .message(let messageItem):
            try container.encode(messageItem)
        }
    }
}

// MARK: ResponseContent

public enum ResponseContent: Sendable {
    case text(TextContent)
    case refusal(TextRefusalContent)
}

extension ResponseContent {
    var text: TextContent? {
        guard case let .text(value) = self else {
            return nil
        }
        return value
    }
    
    var refusal: TextRefusalContent? {
        guard case let .refusal(value) = self else {
            return nil
        }
        return value
    }
}

// MARK: ResponseContent + Codable

extension ResponseContent: Codable {
    enum CodingKeys: String, CodingKey {
        case type
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(GeneratedContentType.self, forKey: .type)
        switch type {
        case .text:
            self = try .text(.init(from: decoder))
        case .textRefusal:
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


// MARK: Content - Text

extension GeneratedContentType {
    public static let text = GeneratedContentType(rawValue: "response.message.text")
}

public struct TextContent: PartialUpdatable, GeneratedItem, Codable {
    // TODO: Support content index
    
    public let type: GeneratedContentType = .text
    
    public let delta: String?
    
    public let content: String?
    public let annotations: [Annotation]
    
    enum CodingKeys: CodingKey {
        case type
        case delta
        case content
        case annotations
    }
}

// MARK: Content - Text Annotation

extension GeneratedContentType {
    static let textAnnotation = GeneratedContentType(rawValue: "response.message.text.annotation")
}

extension TextContent {
    public struct Annotation: GeneratedItem, Codable {
        public let id: String
        public let type: GeneratedContentType = .textAnnotation
        
        public let content: String?
        
        enum CodingKeys: CodingKey {
            case id
            case type
            case content
        }
    }
}

// MARK: Content - Refusal

extension GeneratedContentType {
    static let textRefusal = GeneratedContentType(rawValue: "response.message.text.refusal")
}

public struct TextRefusalContent: GeneratedItem, Codable {
    
    public let type: GeneratedContentType = .textRefusal
    
    public let content: String?
    
    enum CodingKeys: CodingKey {
        case type
        case content
    }
}

// MARK: Message

extension GeneratedContentType {
    public static let message = GeneratedContentType(rawValue: "response.message")
}

public struct MessageItem: Identifiable, GeneratedSortableItem, Codable {
    public let id: String
    public let type: GeneratedContentType = .message
    public let index: Int?
    
    // Text Or TextRefusal
    public let content: [ResponseContent]?
    
    enum CodingKeys: CodingKey {
        case id
        case type
        case index
        case content
    }
}
