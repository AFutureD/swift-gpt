//
//  Content+TextInput.swift
//  swift-gpt
//
//  Created by Huanan on 2025/8/29.
//

extension ContentType {
    static let inputText = ContentType(rawValue: "text")
}


/// A text-based input for a prompt.
public struct TextInputContent: Sendable, Codable, Hashable {
    public let type: ContentType = .inputText
    /// The role of the entity providing the content (e.g., user, assistant).
    public let role: ModelContentRole

    /// The text content.
    public let content: String

    enum CodingKeys: CodingKey {
        case type
        case role
        case content
    }

    /// Creates a new text content item.
    /// - Parameters:
    ///   - role: The role of the entity providing the content.
    ///   - content: The text content.
    public init(role: ModelContentRole, content: String) {
        self.role = role
        self.content = content
    }
}

extension TextInputContent: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(role: .user, content: value)
    }
}
