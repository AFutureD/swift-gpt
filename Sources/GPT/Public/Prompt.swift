//
//  Prompt.swift
//  swift-gpt
//
//  Created by AFuture on 2025/7/12.
//

extension Prompt {
    public enum Input: Sendable {
        case text(TextContent)
        case file(FileContent)
    }
}

extension Prompt.Input: Codable {
    enum CodingKeys: String, CodingKey {
        case type
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ModelInputContentType.self, forKey: .type)
        switch type {
        case .text:
            self = try .text(.init(from: decoder))
        case .file:
            self = try .file(.init(from: decoder))
        default:
            throw DecodingError.typeMismatch(MessageItem.self, .init(codingPath: [], debugDescription: "Only Support 'MessageItem'"))
        }
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text(let value):
            try container.encode(value)
        case .file(let value):
            try container.encode(value)
        }
    }
}


extension Prompt.Input {
    public var content: any ModelInputContent {
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

        public init(role: ModelInputContentRole, content: String) {
            self.role = role
            self.content = content
        }
    }
}

extension Prompt.Input.TextContent: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(role: .user, content: value)
    }
}

extension ModelInputContent {
    public static func text(_ content: Prompt.Input.TextContent) -> any ModelInputContent {
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

        public init(role: ModelInputContentRole, id: String?, filename: String?, content: String) {
            self.role = role
            self.id = id
            self.filename = filename
            self.content = content
        }
    }
}

extension ModelInputContent {
    public static func file(_ content: Prompt.Input.FileContent) -> any ModelInputContent {
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
    
    public let temperature: Double?
    public let topP: Double?
    public let maxTokens: Int?
    
    public init(
        prev_id: String? = nil,
        instructions: String? = nil,
        inputs: [Input],
        store: Bool? = nil,
        stream: Bool = true,
        temperature: Double? = nil,
        topP: Double? = nil,
        maxTokens: Int? = nil
    ) {
        self.prev_id = prev_id
        self.instructions = instructions
        self.inputs = inputs
        self.store = store
        self.stream = stream
        self.temperature = temperature
        self.topP = topP
        self.maxTokens = maxTokens
    }
}
