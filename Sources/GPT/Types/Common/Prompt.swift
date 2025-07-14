//
//  Prompt.swift
//  swift-gpt
//
//  Created by AFuture on 2025/7/12.
//

public struct Prompt {
    /// Optional. Previous Session ID.
    /// In OpenAI Response API, this value should be Response ID
    let prev_id: String?
    
    /// System instructions for the prompt.
    let instructions: String?
    
    // TODO: maybe use OpenAIModelReponseRequestInput instead
    let inputs: OpenAIModelReponseRequestInput  // Node inputs: [OpenAIModelReponseRequestInputItemMessage]
    
    let store: Bool
    
    let stream: Bool
    
    // Not Implement For Now.
    // let tools: [String: Tool]
}

