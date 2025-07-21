//
//  Prompt.swift
//  swift-gpt
//
//  Created by AFuture on 2025/7/12.
//

extension Prompt {
    public enum Input: Codable, Sendable {
        case text(TextContent)
        case file(FileContent)
    }
}

extension Prompt.Input {
    var content: any ModelInputContent {
        switch self {
        case .text(let content):
            return content
        case .file(let content):
            return content
        }
    }
}

// MARK: Text

extension ModelInputContentType {
    static let text = ModelInputContentType(rawValue: "text")
}

extension Prompt.Input {
    public struct TextContent: ModelInputContent, Codable {
        public let type: ModelInputContentType = .text
        public let role: ModelInputContentRole
        
        public let content: String
        
        enum CodingKeys: CodingKey {
            case type
            case role
            case content
        }
    }
}

extension Prompt.Input.TextContent: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(role: .user, content: value)
    }
}

extension ModelInputContent {
    static func text(_ content: Prompt.Input.TextContent) -> any ModelInputContent {
        content
    }
}

// MARK: File

extension ModelInputContentType {
    static let file = ModelInputContentType(rawValue: "File")
}

extension Prompt.Input {
    public struct FileContent: ModelInputContent, Codable {

        public let type: ModelInputContentType = .file
        public let role: ModelInputContentRole
        
        public let id: String?
        
        public let filename: String?

        public let content: String
        
        enum CodingKeys: CodingKey {
            case type
            case role
            case id
            case filename
            case content
        }
    }
}

extension ModelInputContent {
    static func file(_ content: Prompt.Input.FileContent) -> any ModelInputContent {
        content
    }
}

// MARK: Prompt

public struct Prompt: Codable, Sendable {
    /// Optional. Previous Session ID.
    /// In OpenAI Response API, this value should be Response ID
    public let prev_id: String?
    
    /// System instructions for the prompt.
    public let instructions: String?
    
    public let inputs: [Input]
    
    public let store: Bool?
    
    // perfer stream. true, only when caller calls the stream func.
    public let stream: Bool
    
    // Not Implement For Now.
    // let tools: [String: Tool]
    
    public init(prev_id: String? = nil, instructions: String? = nil, inputs: [Input], store: Bool? = nil, stream: Bool = true) {
        self.prev_id = prev_id
        self.instructions = instructions
        self.inputs = inputs
        self.store = store
        self.stream = stream
    }
}
