//
//  Content.swift
//  swift-gpt
//
//  Created by AFuture on 2025/7/21.
//


// MARK: Message

extension GeneratedContentType {
    /// The content type for a message item.
    public static let generatedMessage = GeneratedContentType(rawValue: "response.message")
}

/// A single message item in a response, which can contain multiple content blocks.
public struct MessageItem: Identifiable, Sendable, Codable {
    public let id: String
    public let type: GeneratedContentType = .generatedMessage
    public let index: Int?
    
    /// The content of the message, which can be text or a refusal.
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
