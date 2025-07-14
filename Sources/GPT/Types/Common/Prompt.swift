//
//  Prompt.swift
//  swift-gpt
//
//  Created by AFuture on 2025/7/12.
//

 

extension Prompt {
    enum Input {
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
    struct TextContent: ModelInputContent {
        let type: ModelInputContentType = .text
        let role: ModelInputContentRole
        
        let content: String
    }
}

extension Prompt.Input.TextContent: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
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
    struct FileContent: ModelInputContent {

        let type: ModelInputContentType = .file
        let role: ModelInputContentRole
        
        let id: String?
        
        let filename: String?

        let content: String
    }
}

extension ModelInputContent {
    static func file(_ content: Prompt.Input.FileContent) -> any ModelInputContent {
        content
    }
}

// MARK: Prompt

public struct Prompt {
    /// Optional. Previous Session ID.
    /// In OpenAI Response API, this value should be Response ID
    let prev_id: String?

    /// System instructions for the prompt.
    let instructions: String?

    let inputs: [Input]

    let store: Bool

    // perfer stream. true, only when caller calls the stream func.
    let stream: Bool

    // Not Implement For Now.
    // let tools: [String: Tool]
}
