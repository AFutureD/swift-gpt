//
//  OpenAIChatCompletionRequest.swift
//  swift-workflow
//
//  Created by AFuture on 2025/5/18.
//

@preconcurrency import DynamicJSON
import Foundation

/// Represents the request body for creating a chat completion.
public struct OpenAIChatCompletionRequest: Codable, Sendable {
    /// A list of messages comprising the conversation so far.
    public let messages: [OpenAIChatCompletionRequestMessage]

    /// Model ID used to generate the response.
    public let model: String // TODO: using enum

    /// Parameters for audio output. Required when audio output is requested.
    public let audio: OpenAIChatCompletionRequestAudioOutput?

    /// Defaults to 0. Number between -2.0 and 2.0. Positive values penalize new tokens based on their existing frequency.
    public let frequencyPenalty: Double?

    /// Modify the likelihood of specified tokens appearing in the completion. Maps token IDs (strings) to bias values (-100 to 100).
    public let logitBias: [String: Int]? // WTF?

    /// Defaults to false. Whether to return log probabilities of the output tokens.
    public let logprobs: Bool?

    /// An upper bound for the number of tokens that can be generated for a completion.
    public let maxCompletionTokens: Int?

    /// Set of 16 key-value pairs that can be attached to the object.
    public let metadata: [String: String]?

    /// Output types requested (e.g., ["text", "audio"]). Defaults to ["text"].
    public let modalities: [String]?

    /// How many chat completion choices to generate for each input message. Defaults to 1.
    public let n: Int?

    /// Whether to enable parallel function calling. Defaults to true.
    public let parallelToolCalls: Bool?

    /// Configuration for a Predicted Output to improve response times.
    public let prediction: OpenAIChatCompletionRequestPrediction?

    /// Number between -2.0 and 2.0. Positive values penalize new tokens based on whether they appear in the text so far.
    public let presencePenalty: Double?

    /// Constrains effort on reasoning for o-series models. (low, medium, high). Defaults to medium.
    public let reasoningEffort: OpenAIChatCompletionRequestReasoningEffort?

    /// An object specifying the format that the model must output.
    public let responseFormat: OpenAIChatCompletionRequestResponseFormat?

    /// If specified, attempts to sample deterministically.
    public let seed: Int?

    /// Latency tier to use for processing the request (auto, default).
    public let serviceTier: OpenAIChatCompletionServiceTier?

    /// Up to 4 sequences where the API will stop generating further tokens. Can be a single string or an array of strings.
    public let stop: String?

    /// Whether to store the output for model distillation or evals. Defaults to false.
    public let store: Bool?

    /// If set to true, streams response data using server-sent events. Defaults to false.
    public let stream: Bool?

    /// Options for streaming response. Only set when stream is true.
    public let streamOptions: OpenAIChatCompletionRequestStreamOptions?

    /// Sampling temperature (0 to 2). Higher values = more random, lower = more focused. Defaults to 1.
    public let temperature: Double?

    /// Controls which (if any) tool is called by the model.
    public let toolChoice: OpenAIChatCompletionRequestToolChoice?

    /// A list of tools the model may call. Currently, only functions are supported.
    public let tools: [OpenAIChatCompletionRequestTool]?

    /// Number of most likely tokens to return at each position (0-20). Requires logprobs=true.
    public let topLogprobs: Int?

    /// Nucleus sampling parameter (0 to 1). Considers tokens with top_p probability mass. Defaults to 1.
    public let topP: Double?

    /// A unique identifier representing your end-user.
    public let user: String?

    /// Options for the web search tool.
    public let webSearchOptions: WebSearchOptions?
    
    public let extraBody: [String: DynamicJSON.JSON]
    
    public init(messages: [OpenAIChatCompletionRequestMessage], model: String, audio: OpenAIChatCompletionRequestAudioOutput?, frequencyPenalty: Double?, logitBias: [String : Int]?, logprobs: Bool?, maxCompletionTokens: Int?, metadata: [String : String]?, modalities: [String]?, n: Int?, parallelToolCalls: Bool?, prediction: OpenAIChatCompletionRequestPrediction?, presencePenalty: Double?, reasoningEffort: OpenAIChatCompletionRequestReasoningEffort?, responseFormat: OpenAIChatCompletionRequestResponseFormat?, seed: Int?, serviceTier: OpenAIChatCompletionServiceTier?, stop: String?, store: Bool?, stream: Bool?, streamOptions: OpenAIChatCompletionRequestStreamOptions?, temperature: Double?, toolChoice: OpenAIChatCompletionRequestToolChoice?, tools: [OpenAIChatCompletionRequestTool]?, topLogprobs: Int?, topP: Double?, user: String?, webSearchOptions: WebSearchOptions?, extraBody: [String : DynamicJSON.JSON] = [:]) {
        self.messages = messages
        self.model = model
        self.audio = audio
        self.frequencyPenalty = frequencyPenalty
        self.logitBias = logitBias
        self.logprobs = logprobs
        self.maxCompletionTokens = maxCompletionTokens
        self.metadata = metadata
        self.modalities = modalities
        self.n = n
        self.parallelToolCalls = parallelToolCalls
        self.prediction = prediction
        self.presencePenalty = presencePenalty
        self.reasoningEffort = reasoningEffort
        self.responseFormat = responseFormat
        self.seed = seed
        self.serviceTier = serviceTier
        self.stop = stop
        self.store = store
        self.stream = stream
        self.streamOptions = streamOptions
        self.temperature = temperature
        self.toolChoice = toolChoice
        self.tools = tools
        self.topLogprobs = topLogprobs
        self.topP = topP
        self.user = user
        self.webSearchOptions = webSearchOptions
        self.extraBody = extraBody
    }
}

extension OpenAIChatCompletionRequest {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.messages = try container.decode([OpenAIChatCompletionRequestMessage].self, forKey: .messages)
        self.model = try container.decode(String.self, forKey: .model)
        self.audio = try container.decodeIfPresent(OpenAIChatCompletionRequestAudioOutput.self, forKey: .audio)
        self.frequencyPenalty = try container.decodeIfPresent(Double.self, forKey: .frequencyPenalty)
        self.logitBias = try container.decodeIfPresent([String: Int].self, forKey: .logitBias)
        self.logprobs = try container.decodeIfPresent(Bool.self, forKey: .logprobs)
        self.maxCompletionTokens = try container.decodeIfPresent(Int.self, forKey: .maxCompletionTokens)
        self.metadata = try container.decodeIfPresent([String: String].self, forKey: .metadata)
        self.modalities = try container.decodeIfPresent([String].self, forKey: .modalities)
        self.n = try container.decodeIfPresent(Int.self, forKey: .n)
        self.parallelToolCalls = try container.decodeIfPresent(Bool.self, forKey: .parallelToolCalls)
        self.prediction = try container.decodeIfPresent(OpenAIChatCompletionRequestPrediction.self, forKey: .prediction)
        self.presencePenalty = try container.decodeIfPresent(Double.self, forKey: .presencePenalty)
        self.reasoningEffort = try container.decodeIfPresent(OpenAIChatCompletionRequestReasoningEffort.self, forKey: .reasoningEffort)
        self.responseFormat = try container.decodeIfPresent(OpenAIChatCompletionRequestResponseFormat.self, forKey: .responseFormat)
        self.seed = try container.decodeIfPresent(Int.self, forKey: .seed)
        self.serviceTier = try container.decodeIfPresent(OpenAIChatCompletionServiceTier.self, forKey: .serviceTier)
        self.stop = try container.decodeIfPresent(String.self, forKey: .stop)
        self.store = try container.decodeIfPresent(Bool.self, forKey: .store)
        self.stream = try container.decodeIfPresent(Bool.self, forKey: .stream)
        self.streamOptions = try container.decodeIfPresent(OpenAIChatCompletionRequestStreamOptions.self, forKey: .streamOptions)
        self.temperature = try container.decodeIfPresent(Double.self, forKey: .temperature)
        self.toolChoice = try container.decodeIfPresent(OpenAIChatCompletionRequestToolChoice.self, forKey: .toolChoice)
        self.tools = try container.decodeIfPresent([OpenAIChatCompletionRequestTool].self, forKey: .tools)
        self.topLogprobs = try container.decodeIfPresent(Int.self, forKey: .topLogprobs)
        self.topP = try container.decodeIfPresent(Double.self, forKey: .topP)
        self.user = try container.decodeIfPresent(String.self, forKey: .user)
        self.webSearchOptions = try container.decodeIfPresent(WebSearchOptions.self, forKey: .webSearchOptions)
        
        let extraKeys = Set(container.allKeys).subtracting(CodingKeys.allKeys)
        var extraBody: [String: JSON] = [:]
        
        for key in extraKeys {
            if let value = try? container.decodeIfPresent(JSON.self, forKey: key) {
                extraBody[key.stringValue] = value
            }
        }
        
        self.extraBody = extraBody
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.messages, forKey: .messages)
        try container.encode(self.model, forKey: .model)
        try container.encodeIfPresent(self.audio, forKey: .audio)
        try container.encodeIfPresent(self.frequencyPenalty, forKey: .frequencyPenalty)
        try container.encodeIfPresent(self.logitBias, forKey: .logitBias)
        try container.encodeIfPresent(self.logprobs, forKey: .logprobs)
        try container.encodeIfPresent(self.maxCompletionTokens, forKey: .maxCompletionTokens)
        try container.encodeIfPresent(self.metadata, forKey: .metadata)
        try container.encodeIfPresent(self.modalities, forKey: .modalities)
        try container.encodeIfPresent(self.n, forKey: .n)
        try container.encodeIfPresent(self.parallelToolCalls, forKey: .parallelToolCalls)
        try container.encodeIfPresent(self.prediction, forKey: .prediction)
        try container.encodeIfPresent(self.presencePenalty, forKey: .presencePenalty)
        try container.encodeIfPresent(self.reasoningEffort, forKey: .reasoningEffort)
        try container.encodeIfPresent(self.responseFormat, forKey: .responseFormat)
        try container.encodeIfPresent(self.seed, forKey: .seed)
        try container.encodeIfPresent(self.serviceTier, forKey: .serviceTier)
        try container.encodeIfPresent(self.stop, forKey: .stop)
        try container.encodeIfPresent(self.store, forKey: .store)
        try container.encodeIfPresent(self.stream, forKey: .stream)
        try container.encodeIfPresent(self.streamOptions, forKey: .streamOptions)
        try container.encodeIfPresent(self.temperature, forKey: .temperature)
        try container.encodeIfPresent(self.toolChoice, forKey: .toolChoice)
        try container.encodeIfPresent(self.tools, forKey: .tools)
        try container.encodeIfPresent(self.topLogprobs, forKey: .topLogprobs)
        try container.encodeIfPresent(self.topP, forKey: .topP)
        try container.encodeIfPresent(self.user, forKey: .user)
        try container.encodeIfPresent(self.webSearchOptions, forKey: .webSearchOptions)
        
        for (key, body) in extraBody {
            guard let codingKey = CodingKeys(stringValue: key) else {
                continue
            }
            try container.encodeIfPresent(body, forKey: codingKey)
        }
    }
}

extension OpenAIChatCompletionRequest {
    struct CodingKeys: CodingKey, Hashable {
        var stringValue: String
        
        var intValue: Int?
        
        init?(intValue: Int) {
            return nil
        }
        
        init?(stringValue: String) {
            self.stringValue = stringValue
            intValue = nil
        }
    }
}

extension OpenAIChatCompletionRequest.CodingKeys {
    static let allKeys: [Self] = [
        .messages, .model, .audio, .frequencyPenalty, .logitBias, .logprobs, .maxCompletionTokens, .metadata, .modalities, .n, .parallelToolCalls, .prediction, .presencePenalty, .reasoningEffort, .responseFormat, .seed, .serviceTier, .stop, .store, .stream, .streamOptions, .temperature, .toolChoice, .tools, .topLogprobs, .topP, .user, .webSearchOptions,
    ]
    
    static let messages = Self(stringValue: "messages")!
    static let model = Self(stringValue: "model")!
    static let audio = Self(stringValue: "audio")!
    static let frequencyPenalty = Self(stringValue: "frequency_penalty")!
    static let logitBias = Self(stringValue: "logit_bias")!
    static let logprobs = Self(stringValue: "logprobs")!
    static let maxCompletionTokens = Self(stringValue: "max_completion_tokens")!
    static let metadata = Self(stringValue: "metadata")!
    static let modalities = Self(stringValue: "modalities")!
    static let n = Self(stringValue: "n")!
    static let parallelToolCalls = Self(stringValue: "parallel_tool_calls")!
    static let prediction = Self(stringValue: "prediction")!
    static let presencePenalty = Self(stringValue: "presence_penalty")!
    static let reasoningEffort = Self(stringValue: "reasoning_effort")!
    static let responseFormat = Self(stringValue: "response_format")!
    static let seed = Self(stringValue: "seed")!
    static let serviceTier = Self(stringValue: "service_tier")!
    static let stop = Self(stringValue: "stop")!
    static let store = Self(stringValue: "store")!
    static let stream = Self(stringValue: "stream")!
    static let streamOptions = Self(stringValue: "stream_options")!
    static let temperature = Self(stringValue: "temperature")!
    static let toolChoice = Self(stringValue: "tool_choice")!
    static let tools = Self(stringValue: "tools")!
    static let topLogprobs = Self(stringValue: "top_logprobs")!
    static let topP = Self(stringValue: "topP")!
    static let user = Self(stringValue: "user")!
    static let webSearchOptions = Self(stringValue: "web_search_options")!
}





// MARK: - Message Types

/// Represents the role of the message author.
public enum MessageRole: String, Codable, Sendable {
    case developer
    case system
    case user
    case assistant
    case tool
}

/// Represents a single message in the conversation. Uses an enum to handle different message structures based on role.
public enum OpenAIChatCompletionRequestMessage: Codable, Sendable {
    case developer(OpenAIChatCompletionRequestDeveloperMessage)
    case system(OpenAIChatCompletionRequestSystemMessage)
    case user(OpenAIChatCompletionRequestUserMessage)
    case assistant(OpenAIChatCompletionRequestAssistantMessage)
    case tool(OpenAIChatCompletionRequestToolMessage)

    // Custom Codable, Sendable implementation to handle the different message types
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let role = try container.decode(MessageRole.self, forKey: .role)

        switch role {
        case .developer:
            self = try .developer(OpenAIChatCompletionRequestDeveloperMessage(from: decoder))
        case .system:
            self = try .system(OpenAIChatCompletionRequestSystemMessage(from: decoder))
        case .user:
            self = try .user(OpenAIChatCompletionRequestUserMessage(from: decoder))
        case .assistant:
            self = try .assistant(OpenAIChatCompletionRequestAssistantMessage(from: decoder))
        case .tool:
            self = try .tool(OpenAIChatCompletionRequestToolMessage(from: decoder))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .developer(let message):
            try container.encode(message)
        case .system(let message):
            try container.encode(message)
        case .user(let message):
            try container.encode(message)
        case .assistant(let message):
            try container.encode(message)
        case .tool(let message):
            try container.encode(message)
        }
    }

    // Used internally for decoding based on role
    private enum CodingKeys: String, CodingKey {
        case role
    }
}

// --- Specific Message Structs ---

public struct OpenAIChatCompletionRequestDeveloperMessage: Codable, Sendable {
    public let role: MessageRole = .developer
    public let content: OpenAIChatCompletionRequestMessageContent
    public let name: String?

    enum CodingKeys: CodingKey {
        case role
        case content
        case name
    }
}

public struct OpenAIChatCompletionRequestSystemMessage: Codable, Sendable {
    public let role: MessageRole = .system
    public let content: OpenAIChatCompletionRequestMessageContent
    public let name: String?

    enum CodingKeys: CodingKey {
        case role
        case content
        case name
    }
}

/// Represents content for a user message (either plain text or structured parts).
public enum OpenAIChatCompletionRequestMessageContent: Codable, Sendable {
    case text(String)
    case parts([OpenAIChatCompletionRequestMessageContentPart])

    // Custom Codable, Sendable
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let text = try? container.decode(String.self) {
            self = .text(text)
        } else if let parts = try? container.decode([OpenAIChatCompletionRequestMessageContentPart].self) {
            self = .parts(parts)
        } else {
            throw DecodingError.typeMismatch(OpenAIChatCompletionRequestMessageContent.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Content must be a String or an array of ContentPart"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text(let text):
            try container.encode(text)
        case .parts(let parts):
            try container.encode(parts)
        }
    }
}

public struct OpenAIChatCompletionRequestUserMessage: Codable, Sendable {
    public let role: MessageRole = .user
    public let content: OpenAIChatCompletionRequestMessageContent
    public let name: String?

    enum CodingKeys: CodingKey {
        case role
        case content
        case name
    }
}

public struct OpenAIChatCompletionRequestAssistantAudioMessage: Codable, Sendable {
    public let id: String
}

public struct OpenAIChatCompletionRequestAssistantMessage: Codable, Sendable {
    public let role: MessageRole = .assistant
    public let audio: OpenAIChatCompletionRequestAssistantAudioMessage?
    public let content: OpenAIChatCompletionRequestMessageContent?
    public let name: String?
    public let refusal: String?
    public let tool_calls: [OpenAIChatCompletionRequestAssistantMessageToolCall]?

    enum CodingKeys: CodingKey {
        case role
        case audio
        case content
        case name
        case refusal
        case tool_calls
    }
}

public struct OpenAIChatCompletionRequestToolMessage: Codable, Sendable {
    public let role: MessageRole = .tool
    public let content: OpenAIChatCompletionRequestMessageContent
    public let toolCallId: String

    enum CodingKeys: String, CodingKey {
        case role, content
        case toolCallId = "tool_call_id"
    }
}

public enum OpenAIChatCompletionRequestMessageContentPartType: String, Codable, Sendable {
    case text
    case image_url // JSON uses image_url for image type
    case input_audio // JSON uses input_audio for audio type
    case file
    case refusal
}

/// Represents different types of content parts within a user message.
public enum OpenAIChatCompletionRequestMessageContentPart: Codable, Sendable {
    case text(OpenAIChatCompletionRequestMessageContentTextPart)
    case image(OpenAIChatCompletionRequestMessageContentImagePart)
    case audio(OpenAIChatCompletionRequestMessageContentAudioPart)
    case file(OpenAIChatCompletionRequestMessageContentFilePart)
    case refusal(OpenAIChatCompletionRequestMessageContentRefusalPart)

    // Custom Codable, Sendable implementation
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(OpenAIChatCompletionRequestMessageContentPartType.self, forKey: .type)

        switch type {
        case .text:
            self = try .text(OpenAIChatCompletionRequestMessageContentTextPart(from: decoder))
        case .image_url:
            self = try .image(OpenAIChatCompletionRequestMessageContentImagePart(from: decoder))
        case .input_audio: // Mapped from audio type
            self = try .audio(OpenAIChatCompletionRequestMessageContentAudioPart(from: decoder))
        case .file:
            self = try .file(OpenAIChatCompletionRequestMessageContentFilePart(from: decoder))
        case .refusal:
            self = try .refusal(OpenAIChatCompletionRequestMessageContentRefusalPart(from: decoder))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text(let part):
            try container.encode(part)
        case .image(let part):
            try container.encode(part)
        case .audio(let part):
            try container.encode(part)
        case .file(let part):
            try container.encode(part)
        case .refusal(let part):
            try container.encode(part)
        }
    }

    // Used internally for decoding based on type
    private enum CodingKeys: String, CodingKey {
        case type
    }
}

public struct OpenAIChatCompletionRequestMessageContentTextPart: Codable, Sendable {
    public let type: OpenAIChatCompletionRequestMessageContentPartType = .text
    public let text: String

    enum CodingKeys: CodingKey {
        case type
        case text
    }
}

public enum OpenAIChatCompletionRequestMessageContentImagePartImageDetail: String, Codable, Sendable {
    case auto, low, high
}

public enum OpenAIChatCompletionRequestMessageContentImagePartImageContent: Codable, Sendable {
    case url(String)
    case base64(String)

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()

        let str = try container.decode(String.self)
        if str.starts(with: "http") {
            self = .url(str)
        } else {
            self = .base64(str)
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .url(let a0):
            try container.encode(a0)
        case .base64(let a0):
            try container.encode(a0)
        }
    }
}

public struct OpenAIChatCompletionRequestMessageContentImageContentPartImageURL: Codable, Sendable {
    public let url: OpenAIChatCompletionRequestMessageContentImagePartImageContent
    public let detail: OpenAIChatCompletionRequestMessageContentImagePartImageDetail?
}

/// https://platform.openai.com/docs/guides/images?api-mode=chat&format=base64-encoded
public struct OpenAIChatCompletionRequestMessageContentImagePart: Codable, Sendable {
    public let type: OpenAIChatCompletionRequestMessageContentPartType = .image_url
    public let imageUrl: OpenAIChatCompletionRequestMessageContentImageContentPartImageURL

    enum CodingKeys: String, CodingKey {
        case type
        case imageUrl = "image_url"
    }
}

public enum OpenAIChatCompletionRequestMessageContentAudioPartAudioDataFormat: String, Codable, Sendable {
    case wav, mp3 // Add others if supported by API
}

public struct OpenAIChatCompletionRequestMessageContentAudioPartInput: Codable, Sendable {
    public let data: String // Base64 encoded audio data
    public let format: OpenAIChatCompletionRequestMessageContentAudioPartAudioDataFormat
}

/// https://platform.openai.com/docs/guides/audio
public struct OpenAIChatCompletionRequestMessageContentAudioPart: Codable, Sendable {
    public let type: OpenAIChatCompletionRequestMessageContentPartType = .input_audio
    public let inputAudio: OpenAIChatCompletionRequestMessageContentAudioPartInput

    enum CodingKeys: String, CodingKey {
        case type
        case inputAudio = "input_audio"
    }
}

/// https://platform.openai.com/docs/guides/pdf-files?api-mode=chat
public struct OpenAIChatCompletionRequestMessageContentFilePartDetail: Codable, Sendable {
    public let fileId: String?
    public let filename: String?
    public let fileData: String? // The base64 encoded file data, used when passing the file to the model as a string.

    enum CodingKeys: String, CodingKey {
        case fileId = "file_id"
        case filename
        case fileData = "file_data"
    }
}

public struct OpenAIChatCompletionRequestMessageContentFilePart: Codable, Sendable {
    public let type: OpenAIChatCompletionRequestMessageContentPartType = .file
    public let file: OpenAIChatCompletionRequestMessageContentFilePartDetail

    enum CodingKeys: CodingKey {
        case type
        case file
    }
}

public struct OpenAIChatCompletionRequestMessageContentRefusalPart: Codable, Sendable {
    public let type: OpenAIChatCompletionRequestMessageContentPartType = .refusal
    public let refusal: String

    enum CodingKeys: CodingKey {
        case type
        case refusal
    }
}

// MARK: - Tool Calls (Assistant Message)

/// Represents a tool call made by the assistant. Currently only function calls are supported.
public struct OpenAIChatCompletionRequestAssistantMessageToolCall: Codable, Sendable {
    /// The ID of the tool call.
    public let id: String
    /// The type of the tool. Currently, only "function" is supported.
    public let type: String
    /// The function that the model called.
    public let function: OpenAIChatCompletionRequestAssistantMessageToolCallCalledFunction
}

/// Represents the function called by the model within a ToolCall.
public struct OpenAIChatCompletionRequestAssistantMessageToolCallCalledFunction: Codable, Sendable {
    /// The name of the function to call.
    public let name: String
    /// The arguments to call the function with, as a JSON format string.
    public let arguments: String // Model generates JSON string
}

// MARK: - Tools

/// Represents a tool choice (string 'none', 'auto', 'required' or specific tool).
public enum OpenAIChatCompletionRequestToolChoice: Codable, Sendable {
    case none
    case auto
    case required
    case tool(OpenAIChatCompletionRequestToolChoiceSpecificTool)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let text = try? container.decode(String.self) {
            switch text {
            case "none": self = .none
            case "auto": self = .auto
            case "required": self = .required
            default:
                throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "OpenAIChatCompletionRequestToolChoice Can't decode"))
            }
            return
        }
        let tool = try container.decode(OpenAIChatCompletionRequestToolChoiceSpecificTool.self)
        self = .tool(tool)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .none: try container.encode("none")
        case .auto: try container.encode("auto")
        case .required: try container.encode("required")
        case .tool(let toolChoice): try container.encode(toolChoice)
        }
    }
}

public struct OpenAIChatCompletionRequestToolChoiceSpecificToolFunction: Codable, Sendable {
    public let name: String
}

/// Represents a choice to call a specific tool (currently only function).
public struct OpenAIChatCompletionRequestToolChoiceSpecificTool: Codable, Sendable {
    public let type: String = "function"
    public let function: OpenAIChatCompletionRequestToolChoiceSpecificToolFunction // Reusing NamedFunction structure

    enum CodingKeys: CodingKey {
        case type
        case function
    }
}

/// Represents a tool available to the model. Currently only functions are supported.
public struct OpenAIChatCompletionRequestTool: Codable, Sendable {
    public let type: String = "function"
    public let function: OpenAIChatCompletionRequestToolFunction

    enum CodingKeys: CodingKey {
        case type
        case function
    }
}

/// Describes a function tool available to the model.
///
/// https://platform.openai.com/docs/guides/function-calling?api-mode=chat
/// https://json-schema.org/understanding-json-schema/reference
public struct OpenAIChatCompletionRequestToolFunction: Codable, Sendable {
    public let name: String
    public let description: String?
    public let parameters: DynamicJSON.JSONSchema?

    // https://platform.openai.com/docs/guides/structured-outputs?api-mode=responses
    public let strict: Bool?
}

// MARK: - Other Supporting Structures

/// Represents the format/voice for audio output.
public struct OpenAIChatCompletionRequestAudioOutput: Codable, Sendable {
    /// Output audio format (wav, mp3, flac, opus, pcm16).
    public let format: OpenAIChatCompletionRequestAudioOutputFormat
    /// Voice to use (alloy, ash, ballad, coral, echo, sage, shimmer).
    public let voice: OpenAIChatCompletionRequestAudioOutputVoice
}

public enum OpenAIChatCompletionRequestAudioOutputFormat: String, Codable, Sendable {
    case wav, mp3, flac, opus, pcm16
}

public enum OpenAIChatCompletionRequestAudioOutputVoice: String, Codable, Sendable {
    case alloy, ash, ballad, coral, echo, sage, shimmer
}

/// Represents the prediction configuration. Currently only StaticContent shown.
public struct OpenAIChatCompletionRequestPrediction: Codable, Sendable {
    public let content: OpenAIChatCompletionRequestMessageContent
    public let type: String
}

public enum OpenAIChatCompletionRequestReasoningEffort: String, Codable, Sendable {
    case low, medium, high
}

public enum OpenAIChatCompletionRequestResponseFormatType: String, Codable, Sendable {
    case text
    case json_schema
    case json_object
}

/// Specifies the desired response format.
public enum OpenAIChatCompletionRequestResponseFormat: Codable, Sendable {
    case text(OpenAIChatCompletionRequestResponseTextFormat)
    case jsonSchema(OpenAIChatCompletionRequestResponseFormatJSONSchemaFormat)
    case jsonObject(OpenAIChatCompletionRequestResponseFormatJSONObjectFormat)

    // Custom Codable, Sendable
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(OpenAIChatCompletionRequestResponseFormatType.self, forKey: .type)

        switch type {
        case .text:
            // Text format might just be implicit or have 'text' type but no other fields
            // Let's assume a simple struct for consistency
            self = try .text(OpenAIChatCompletionRequestResponseTextFormat(from: decoder))
        case .json_schema:
            self = try .jsonSchema(OpenAIChatCompletionRequestResponseFormatJSONSchemaFormat(from: decoder))
        case .json_object:
            self = try .jsonObject(OpenAIChatCompletionRequestResponseFormatJSONObjectFormat(from: decoder))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text(let format):
            try container.encode(format)
        case .jsonSchema(let format):
            try container.encode(format)
        case .jsonObject(let format):
            try container.encode(format)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type
    }
}

public struct OpenAIChatCompletionRequestResponseTextFormat: Codable, Sendable {
    public let type: OpenAIChatCompletionRequestResponseFormatType = .text

    enum CodingKeys: CodingKey {
        case type
    }
}

public struct OpenAIChatCompletionRequestResponseFormatJSONSchemaFormat: Codable, Sendable {
    public let type: OpenAIChatCompletionRequestResponseFormatType = .json_schema
    public let jsonSchema: OpenAIChatCompletionRequestResponseFormatJSONSchemaFormatDefinition

    enum CodingKeys: String, CodingKey {
        case type
        case jsonSchema = "json_schema"
    }
}

public struct OpenAIChatCompletionRequestResponseFormatJSONSchemaFormatDefinition: Codable, Sendable {
    public let name: String
    public let description: String?
    public let schema: DynamicJSON.JSONSchema?
    public let strict: Bool?
}

public struct OpenAIChatCompletionRequestResponseFormatJSONObjectFormat: Codable, Sendable {
    public let type: OpenAIChatCompletionRequestResponseFormatType = .json_object

    enum CodingKeys: CodingKey {
        case type
    }
}

public enum OpenAIChatCompletionServiceTier: String, Codable, Sendable {
    case auto, flex, `default`
}

/// Options for streaming responses.
public struct OpenAIChatCompletionRequestStreamOptions: Codable, Sendable {
    public let includeUsage: Bool?

    enum CodingKeys: String, CodingKey {
        case includeUsage = "include_usage"
    }
}

/// Options for web search tool.
public struct WebSearchOptions: Codable, Sendable {
    public let searchContextSize: SearchContextSize?
    public let userLocation: UserLocation?

    enum CodingKeys: String, CodingKey {
        case searchContextSize = "search_context_size"
        case userLocation = "user_location"
    }

    public init(searchContextSize: SearchContextSize? = .medium, userLocation: UserLocation? = nil) {
        self.searchContextSize = searchContextSize
        self.userLocation = userLocation
    }
}

public enum SearchContextSize: String, Codable, Sendable {
    case low, medium, high
}

public struct UserLocation: Codable, Sendable {
    public let type: String
    public let approximate: ApproximateLocation? // Only approximate shown in docs

    public init(approximate: ApproximateLocation?) {
        self.approximate = approximate
        self.type = "approximate"
    }
}

public struct ApproximateLocation: Codable, Sendable {
    public let city: String? // Free text input for the city of the user,
    public let country: String? // https://en.wikipedia.org/wiki/ISO_3166-1
    public let region: String? // Free text input for the region of the user
    public let timezone: String? // https://timeapi.io/documentation/iana-timezones

    public init(city: String? = nil, country: String? = nil, region: String? = nil, timezone: String? = nil) {
        self.city = city
        self.country = country
        self.region = region
        self.timezone = timezone
    }
}
