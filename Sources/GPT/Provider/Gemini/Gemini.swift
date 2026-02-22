import Foundation
import HTTPTypes
import LazyKit
import Logging
import NetworkKit
import OpenAPIRuntime
import ServiceContextModule
import TraceKit
import Tracing
import Gemini

struct GeminiProvider: LLMProvider {
    func generate(
        client: ClientTransport,
        provider: LLMProviderConfiguration,
        model: LLMModel,
        _ prompt: Prompt,
        conversation: Conversation,
        logger: Logger,
        serviceContext: ServiceContext
    ) async throws -> AnyAsyncSequence<ModelStreamResponse> {
        todo()
    }
    

    func generate(
        client: ClientTransport,
        provider: LLMProviderConfiguration,
        model: LLMModel,
        _ prompt: Prompt,
        conversation: Conversation,
        logger: Logger,
        serviceContext: ServiceContext
    ) async throws -> ModelResponse {
        
        // let request = Google_Ai_Generativelanguage_V1beta_GenerateContentRequest()
        
        todo()  
    }
}