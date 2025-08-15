//
//  Content.swift
//  swift-gpt
//
//  Created by AFuture on 2025/7/21.
//

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

    public init(delta: String?, content: String?, annotations: [Annotation]) {
        self.delta = delta
        self.content = content
        self.annotations = annotations
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

        public init(id: String, content: String?) {
            self.id = id
            self.content = content
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

    public init(content: String?) {
        self.content = content
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

    public init(id: String, index: Int?, content: [ResponseContent]?) {
        self.id = id
        self.index = index
        self.content = content
    }
}
