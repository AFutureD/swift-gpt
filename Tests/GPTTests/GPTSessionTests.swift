import Testing
import OpenAPIAsyncHTTPClient
import OpenAPIRuntime
@testable import GPT
import HTTPTypes
import Logging
import Foundation
import LazyKit

@Suite("GPTSession Tests")
struct GPTSessionTests {
    
    var provider = LLMProviderConfiguration(
        type: .OpenAI,
        name: "Provider1",
        apiKey: "key1",
        apiURL: "https://invalid1.test.com"
    )
    
    func buildFakeModel(_ name: String) -> LLMModelReference {
        LLMModelReference(
            model: LLMModel(name: name),
            provider: provider
        )
    }
    
    @Test("GPTSession send with LLMQualifiedModel - empty models list")
    func testSendWithEmptyModelsList() async throws {
        let client = AsyncHTTPClientTransport()
        let session = GPTSession(client: client)
        
        let qualifiedModel = LLMQualifiedModel(
            name: "EmptyModel",
            models: []
        )
        
        let prompt = Prompt(
            instructions: "Test",
            inputs: [.text(.init(role: .user, content: "Hello"))]
        )
        
        await #expect(throws: RuntimeError.emptyModelList) {
            _ = try await session.stream(prompt, model: qualifiedModel)
        }
    }
    
    @Test("GPTSession send with LLMQualifiedModel - single model")
    func testSendWithSingleModel() async throws {
        let client = AsyncHTTPClientTransport()
        let session = GPTSession(client: client)

        let qualifiedModel = LLMQualifiedModel(
            name: "TestModel",
            models: [buildFakeModel("foo")]
        )
        
        let prompt = Prompt(
            instructions: "Test",
            inputs: [.text(.init(role: .user, content: "Hello"))]
        )
        
        do {
            _ = try await session.stream(prompt, model: qualifiedModel)
            Issue.record("Should have thrown error due to invalid configuration")
        } catch {
            #expect(error is RuntimeError)
        }
    }
    
    @Test("GPTSession with retry adviser preferNextProvider")
    func testRetryAdviserPreferNextProvider() async throws {
        let strategy = RetryAdviser.Strategy(
            maxAttemptsPerProvider: 1,
            preferNextProvider: true
        )
        let retryAdviser = RetryAdviser(strategy: strategy)
        let client = AsyncHTTPClientTransport()
        let session = GPTSession(client: client, retryAdviser: retryAdviser)

        let qualifiedModel = LLMQualifiedModel(
            name: "TestModel",
            models: [buildFakeModel("foo"), buildFakeModel("bar")]
        )
        
        let prompt = Prompt(
            instructions: "Test",
            inputs: [.text(.init(role: .user, content: "Hello"))]
        )
        
        do {
            _ = try await session.stream(prompt, model: qualifiedModel)
            Issue.record("Should have thrown error")
        } catch let error as RuntimeError {
            if case .retryFailed(let errors) = error {
                #expect(errors.count == 2)
            } else {
                Issue.record("Expected retryFailed error")
            }
        }
    }
}
