//
//  OpenAIChatCompletionResponse.swift
//  swift-workflow
//
//  Created by AFuture on 2025/5/20.
//


struct OpenAIChatCompletionResponse: Codable, Sendable {
    let choices: [OpenAIChatCompletionResponseChoice]
    
    let created: Int
    
    let id: String
    
    let model: String
    
    let object: String = "chat.completion.chunk"
    
    let service_tier: OpenAIChatCompletionServiceTier?
    
    let system_fingerprint: String
    
    let usage: OpenAIChatCompletionResponseUsage?
    
    enum CodingKeys: CodingKey {
        case choices
        case created
        case id
        case model
        case object
        case service_tier
        case system_fingerprint
        case usage
    }
}

struct OpenAIChatCompletionResponseChoice: Codable, Sendable {
    let index: Int
    let finish_reason: String?
    let logprobs: OpenAIChatCompletionResponseChoiceLogprobs?
    let message: OpenAIChatCompletionResponseChoiceMessage
}

struct OpenAIChatCompletionResponseChoiceMessage: Codable, Sendable {
    let content: String?
    let refusal: String?
    let role: String
    let annotations: [OpenAIChatCompletionResponseChoiceMessageAnnotation]?
    let audio: [OpenAIChatCompletionResponseChoiceMessageAudio]?
    let tool_calls: [OpenAIChatCompletionResponseChoiceDeltaToolCall]?
}

struct OpenAIChatCompletionResponseChoiceMessageAnnotation: Codable, Sendable {
    let type: String = "url_citation"
    let url_citation: OpenAIChatCompletionResponseChoiceMessageAnnotationURLCitation
    
    enum CodingKeys: CodingKey {
        case type
        case url_citation
    }
}

struct OpenAIChatCompletionResponseChoiceMessageAnnotationURLCitation: Codable, Sendable {
    let end_index: Int
    let strat_index: Int
    let title: String
    let url: String
}

struct OpenAIChatCompletionResponseChoiceMessageAudio: Codable, Sendable {
    let data: String
    let expires_at: Int
    let id: String
    let trancript: String
}


public struct OpenAIChatCompletionStreamResponse: Codable, Sendable {
    public let choices: [OpenAIChatCompletionStreamResponseChoice]
    
    public let created: Int
    
    public let id: String
    
    public let model: String
    
    public let object: String = "chat.completion.chunk"
    
    public let service_tier: OpenAIChatCompletionServiceTier?
    
    public let system_fingerprint: String?
    
    public let usage: OpenAIChatCompletionResponseUsage?
    
    public enum CodingKeys: CodingKey {
        case choices
        case created
        case id
        case model
        case object
        case service_tier
        case system_fingerprint
        case usage
    }
}

public struct OpenAIChatCompletionResponseUsage: Codable, Sendable {
    public  let completion_tokens: Int
    public let prompt_tokens: Int
    public let total_tokens: Int
    public let completion_tokens_details: OpenAIChatCompletionResponseUsageCompletionDetails?
    public let prompt_tokens_details: OpenAIChatCompletionResponseUsagePromptDetails?
}

public struct OpenAIChatCompletionResponseUsageCompletionDetails: Codable, Sendable {
    public let accepted_prediction_tokens: Int
    public let audio_tokens: Int
    public let reasoning_tokens: Int
    public let rejected_prediction_tokens: Int
}

public struct OpenAIChatCompletionResponseUsagePromptDetails: Codable, Sendable {
    let audio_tokens: Int
    let cached_tokens: Int
    
}

public struct OpenAIChatCompletionStreamResponseChoice: Codable, Sendable {
    public let index: Int
    public let finish_reason: String?
    public let logprobs: OpenAIChatCompletionResponseChoiceLogprobs?
    public let delta: OpenAIChatCompletionStreamResponseChoiceDelta
}

public struct OpenAIChatCompletionResponseChoiceLogprobs: Codable, Sendable {
    let content: [OpenAIChatCompletionResponseChoiceLogprobsInfo]?
    let refusal: [OpenAIChatCompletionResponseChoiceLogprobsInfo]?
}

public struct OpenAIChatCompletionResponseChoiceLogprobsInfo: Codable, Sendable {
    let bytes: [String]
    let logprob: Double
    let token: String
    let top_logprobs: [OpenAIChatCompletionResponseChoiceLogprobsInfo]
}

public struct OpenAIChatCompletionStreamResponseChoiceDelta: Codable, Sendable {
    public let content: String?
    public let refusal: String?
    public let role: String?
    public let tool_calls: [OpenAIChatCompletionResponseChoiceDeltaToolCall]?
}

public struct OpenAIChatCompletionResponseChoiceDeltaToolCall: Codable, Sendable {
    public let index: Int
    public let function: OpenAIChatCompletionResponseChoiceDeltaToolCallFunction
    public let id: String
    public let type: String = "function"
    
    public enum CodingKeys: CodingKey {
        case index
        case function
        case id
        case type
    }
}

public struct OpenAIChatCompletionResponseChoiceDeltaToolCallFunction: Codable, Sendable {
    public let arguments: String
    public let name: String
}
