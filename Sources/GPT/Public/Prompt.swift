//
//  Prompt.swift
//  swift-gpt
//
//  Created by AFuture on 2025/7/12.
//

import DynamicJSON

// MARK: Prompt + Input

public extension Prompt {
    /// Represents a single input item in a prompt, which can be either text or a file.
    enum Input: Hashable, Sendable {
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

public extension Prompt.Input {
    var role: ModelContentRole {
        switch self {
        case .text(let text):
            return text.role
        case .file(let file):
            return file.role
        }
    }
}

public extension Prompt.Input {
    var text: TextInputContent? {
        guard case .text(let text) = self else { return nil }
        return text
    }

    var file: FileInputContent? {
        guard case .file(let file) = self else { return nil }
        return file
    }
}

// MARK: Prompt + Instructions

public extension Prompt {
    enum Instructions: Hashable, Sendable {
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
        if case .text(let string) = self {
            return string
        }
        return nil
    }

    var inputs: [Prompt.Input]? {
        if case .inputs(let items) = self {
            return items
        }
        return nil
    }
}

// MARK: GenerationControl

/// The hyperparameters used for model generation.
public struct GenerationControl: Codable, Sendable {
    /// The temperature for sampling, controlling the randomness of the output. Higher values (e.g., 0.8) make the output more random, while lower values (e.g., 0.2) make it more deterministic.
    public let temperature: Double?

    /// The nucleus sampling probability, controlling the diversity of the output.
    public let topP: Double?

    /// The maximum number of tokens to generate in the response.
    public let maxTokens: Int?

    /// An optional flag indicating whether the prompt and its response should be stored.
    public let store: Bool?
}

// MARK: Prompt + ContextControl

public extension Prompt {
    /// Parameters that control the model’s context window.
    struct ContextControl: Codable, Sendable {
        /// The maximum number of items to include in the context.
        ///
        /// The instructions will not be included.
        public let maxItemCount: Int?
    }
}

// MARK: Prompt

/// Represents a prompt to be sent to an LLM.
public struct Prompt: Sendable {
    /// An optional identifier for the current conversation, used for maintaining context.
    public let conversationID: String?

    /// System-level instructions that guide the model's behavior for the entire conversation.
    public let instructions: Instructions?

    /// The sequence of inputs that make up the prompt.
    public let inputs: [Input]

    public let extraBody: [String: DynamicJSON.JSON]?

    /// A flag indicating whether to use streaming for the response.
    /// This should be `true` when calling `stream(prompt:model:)` and `false` for `generate(prompt:model:)`.
    public let stream: Bool

    // Not Implement For Now.
    // let tools: [String: Tool]

    /// Controls the generation process.
    public let generation: GenerationControl?

    /// Controls the context of the prompt.
    public let context: ContextControl?

    /// Creates a new prompt.
    ///
    /// - Parameters:
    ///   - conversationID: An optional identifier for the current conversation.
    ///   - instructions: System-level instructions for the model.
    ///   - inputs: The sequence of inputs for the prompt.
    ///   - stream: A flag indicating whether to use streaming.
    ///   - generation: Controls the generation process.
    ///   - context: Controls the context of the prompt.
    public init(
        conversationID: String? = nil,
        instructions: Instructions? = nil,
        inputs: [Input],
        extraBody: [String: DynamicJSON.JSON]? = nil,
        stream: Bool = true,
        generation: GenerationControl? = nil,
        context: ContextControl? = nil
    ) {
        self.conversationID = conversationID
        self.instructions = instructions
        self.inputs = inputs
        self.extraBody = extraBody
        self.stream = stream
        self.generation = generation
        self.context = context
    }
}

extension Prompt: Codable {
    public enum CodingKeys: CodingKey {
        case conversationID
        case instructions
        case inputs
        case extraBody
        case store
        case stream
        case generation
        case context

        // deprecated.
        case temperature
        case topP
        case maxTokens
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.conversationID = try container.decodeIfPresent(String.self, forKey: .conversationID)
        self.instructions = try container.decodeIfPresent(Prompt.Instructions.self, forKey: .instructions)
        self.inputs = try container.decode([Prompt.Input].self, forKey: .inputs)
        self.extraBody = try container.decodeIfPresent([String: DynamicJSON.JSON].self, forKey: .extraBody)
        self.stream = try container.decode(Bool.self, forKey: .stream)
        self.context = try container.decodeIfPresent(Prompt.ContextControl.self, forKey: .context)

        if let value = try? container.decodeIfPresent(GenerationControl.self, forKey: .generation) {
            self.generation = value
        } else {
            let store = try? container.decodeIfPresent(Bool.self, forKey: .store)
            let temperature = try? container.decodeIfPresent(Double.self, forKey: .temperature)
            let topP = try? container.decodeIfPresent(Double.self, forKey: .topP)
            let maxTokens = try? container.decodeIfPresent(Int.self, forKey: .maxTokens)
            self.generation = .init(temperature: temperature, topP: topP, maxTokens: maxTokens, store: store)
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(stream, forKey: .stream)
        try container.encode(inputs, forKey: .inputs)
        try container.encodeIfPresent(extraBody, forKey: .extraBody)
        try container.encodeIfPresent(conversationID, forKey: .conversationID)
        try container.encodeIfPresent(instructions, forKey: .instructions)
        try container.encodeIfPresent(context, forKey: .context)
        try container.encodeIfPresent(generation, forKey: .generation)
    }
}
