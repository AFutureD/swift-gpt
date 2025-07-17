import Testing
import OpenAPIAsyncHTTPClient
@testable import GPT
import os.log
import TestKit
import SwiftDotenv

@Test("testExmaple")
func testExmaple() async throws {
    try Dotenv.make()
    
    let client = AsyncHTTPClientTransport()
    let session = GPTSession(client: client)
    
    let prompt = Prompt(
        instructions: """
            be an echo server.
            what I send to you, you send back.

            the exceptions:
            1. send "ping", back "pong"
            2. send "ding", back "dang"
            """,
        inputs: [
            .text(.init(role: .user, content: "Ping"))
        ]
    )
    let openai = LLMProvider(type: .OpenAI, name: "OpenAI", apiKey: Dotenv["OPENAI_API_KEY"]!.stringValue, apiURL: "https://api.openai.com/v1")
    let model = LLMQualifiedModel(name: "gpt-4o", provider: openai)
    let response = try await session.send(prompt, model: model)
   
    let logger = Logger()
    for try await event in response {
        logger.info("\(String(describing: event))")
    }
}


@Test("testExmaple2")
func testExmaple2() async throws {
    try Dotenv.make()
    
    let client = AsyncHTTPClientTransport()
    let session = GPTSession(client: client)
    
    let prompt = Prompt(
        instructions: """
            be an echo server.
            what I send to you, you send back.
            
            the exceptions:
            1. send "ping", back "pong"
            2. send "ding", back "dang"
            """,
        inputs: [
            .text(.init(role: .user, content: "Ping"))
        ]
    )
    let openai = LLMProvider(type: .OpenAICompatible, name: "OpenAI", apiKey: Dotenv["OPENAI_API_KEY"]!.stringValue, apiURL: "https://api.openai.com/v1")
    let model = LLMQualifiedModel(name: "gpt-4o", provider: openai)
    let response = try await session.send(prompt, model: model)
    
    let logger = Logger()
    for try await event in response {
        logger.info("\(String(describing: event))")
    }
}
