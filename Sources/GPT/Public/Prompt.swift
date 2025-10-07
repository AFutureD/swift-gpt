//
//  Prompt.swift
//  swift-gpt
//
//  Created by AFuture on 2025/7/12.
//

// MARK: Prompt + Input

extension Prompt {
    /// Represents a single input item in a prompt, which can be either text or a file.
    public enum Input: Hashable, Sendable {

        /// A text-based input.
        case text(TextInputContent)
        /// A file-based input.
        case file(FileInputContent)
    }
}

extension Prompt.Input: Codable {
    enum CodingKeys: String, CodingKey {
        case type
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ContentType.self, forKey: .type)
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

    public var text: TextInputContent? {
        guard case .text(let text) = self else { return nil }
        return text
    }

    public var file: FileInputContent? {
        guard case .file(let file) = self else { return nil }
        return file
    }
}

// MARK: Prompt + Instructions

extension Prompt {
    public enum Instructions: Hashable, Sendable {
        case text(String)
        case inputs([Input])
    }
}

extension Prompt.Instructions: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self = .text(value)
            return
        } else if let value = try? container.decode([Prompt.Input].self) {
            self = .inputs(value)
            return
        }

        throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Prompt.Instructions is not `String` or `[Prompt.Input]`"))
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .text(let string):
            try container.encode(string)
        case .inputs(let array):
            try container.encode(array)
        }
    }
}

extension Prompt.Instructions: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self = .text(value)
    }
}

extension Prompt.Instructions {
    var text: String? {
        if case let .text(string) = self {
            return string
        }
        return nil
    }
    
    var inputs: [Prompt.Input]? {
        if case let .inputs(items) = self {
            return items
        }
        return nil
    }
}

// MARK: Prompt

/// Represents a prompt to be sent to an LLM.
public struct Prompt: Codable, Sendable {
    /// An optional identifier for the current conversation, used for maintaining context.
    public let conversationID: String?
    
    /// System-level instructions that guide the model's behavior for the entire conversation.
    public let instructions: Instructions?
    
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
    ///   - conversationID: An optional identifier for the current conversation.
    ///   - instructions: System-level instructions for the model.
    ///   - inputs: The sequence of inputs for the prompt.
    ///   - store: An optional flag to store the prompt and response.
    ///   - stream: A flag indicating whether to use streaming.
    ///   - temperature: The temperature for sampling.
    ///   - topP: The nucleus sampling probability.
    ///   - maxTokens: The maximum number of tokens to generate.
    public init(
        conversationID: String? = nil,
        instructions: Instructions? = nil,
        inputs: [Input],
        store: Bool? = nil,
        stream: Bool = true,
        temperature: Double? = nil,
        topP: Double? = nil,
        maxTokens: Int? = nil
    ) {
        self.conversationID = conversationID
        self.instructions = instructions
        self.inputs = inputs
        self.store = store
        self.stream = stream
        self.temperature = temperature
        self.topP = topP
        self.maxTokens = maxTokens
    }
}
