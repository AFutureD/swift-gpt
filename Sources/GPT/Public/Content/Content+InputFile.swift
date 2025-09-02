//
//  Content+FileInput.swift
//  swift-gpt
//
//  Created by Huanan on 2025/8/29.
//

// MARK: File

extension ContentType {
    static let inputFile = ContentType(rawValue: "File")
}

/// A file-based input for a prompt.
public struct FileInputContent: Sendable, Codable {

    public let type: ContentType = .inputFile
    /// The role of the entity providing the content.
    public let role: ModelContentRole

    /// An optional identifier for the file.
    public let id: String?

    /// An optional filename for the file.
    public let filename: String?

    /// The content of the file, typically base64-encoded.
    public let content: String

    enum CodingKeys: CodingKey {
        case type
        case role
        case id
        case filename
        case content
    }

    /// Creates a new file content item.
    /// - Parameters:
    ///   - role: The role of the entity providing the content.
    ///   - id: An optional identifier for the file.
    ///   - filename: An optional filename for the file.
    ///   - content: The content of the file.
    public init(role: ModelContentRole, id: String?, filename: String?, content: String) {
        self.role = role
        self.id = id
        self.filename = filename
        self.content = content
    }
}
