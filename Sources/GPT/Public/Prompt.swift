//
//  Prompt.swift
//  swift-gpt
//
//  Created by AFuture on 2025/7/12.
//

extension Prompt {
    /// Represents a single input item in a prompt, which can be either text or a file.
    public enum Input: Sendable {
        public typealias TextContent = TextInputContent
        public typealias FileContent = FileInputContent

        /// A text-based input.
        case text(TextContent)
        /// A file-based input.
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
        case .inputText:
            self = try .text(.init(from: decoder))
        case .inputFile:
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
    public var role: ModelContentRole {
        switch self {
        case .text(let text):
            return text.role
        case .file(let file):
            return file.role
        }
    }
}


extension Prompt.Input {


    public var text: TextContent? {
        guard case .text(let text) = self else { return nil }
        return text
    }

    public var file: FileContent? {
        guard case .file(let file) = self else { return nil }
        return file
    }
}


// extension Prompt.Input {
//     /// The underlying content of the input.
//     public var content: any ModelInputContent {
//         switch self {
//         case .text(let content):
//             return content
//         case .file(let content):
//             return content
//         }
//     }
// }


// extension ModelInputContent {
//     public static func text(_ content: Prompt.Input.TextContent) -> any ModelInputContent {
//         content
//     }
// }


// extension ModelInputContent {
//     public static func file(_ content: Prompt.Input.FileContent) -> any ModelInputContent {
//         content
//     }
// }

// MARK: Prompt

/// Represents a prompt to be sent to an LLM.
public struct Prompt: Codable, Sendable {
    /// An optional identifier for the previous session, used for maintaining context.
    /// In the OpenAI API, this corresponds to the response ID.
    public let prev_id: String?
    
    /// System-level instructions that guide the model's behavior for the entire conversation.
    public let instructions: String?
    
    /// The sequence of inputs that make up the prompt.
    public let inputs: [Input]
    
    /// An optional flag indicating whether the prompt and its response should be stored.
    public let store: Bool?
    
    /// A flag indicating whether to use streaming for the response.
    /// This should be `true` when calling `stream(prompt:model:)` and `false` for `generate(prompt:model:)`.
    public let stream: Bool
    
    // Not Implement For Now.
    // let tools: [String: Tool]
    
    /// The temperature for sampling, controlling the randomness of the output. Higher values (e.g., 0.8) make the output more random, while lower values (e.g., 0.2) make it more deterministic.
    public let temperature: Double?

    /// The nucleus sampling probability, controlling the diversity of the output.
    public let topP: Double?
    
    /// The maximum number of tokens to generate in the response.
    public let maxTokens: Int?
    
    /// Creates a new prompt.
    ///
    /// - Parameters:
    ///   - prev_id: An optional identifier for the previous session.
    ///   - instructions: System-level instructions for the model.
    ///   - inputs: The sequence of inputs for the prompt.
    ///   - store: An optional flag to store the prompt and response.
    ///   - stream: A flag indicating whether to use streaming.
    ///   - temperature: The temperature for sampling.
    ///   - topP: The nucleus sampling probability.
    ///   - maxTokens: The maximum number of tokens to generate.
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
