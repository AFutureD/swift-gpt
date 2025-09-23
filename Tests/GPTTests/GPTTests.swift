import Testing
import OpenAPIAsyncHTTPClient
@testable import GPT
import os.log
import TestKit
import SwiftDotenv
import Foundation

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
    let openai = LLMProviderConfiguration(type: .OpenAI, name: "OpenAI", apiKey: Dotenv["OPENAI_API_KEY"]!.stringValue, apiURL: "https://api.openai.com/v1")
    let model = LLMModelReference(model: .init(name: "gpt-4o"), provider: openai)
    let response = try await session.stream(prompt, model: model)
   
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
    let openai = LLMProviderConfiguration(type: .OpenAICompatible, name: "OpenAI", apiKey: Dotenv["OPENAI_API_KEY"]!.stringValue, apiURL: "https://api.openai.com/v1")
    let model = LLMModelReference(model: .init(name: "gpt-4o"), provider: openai)
    let response = try await session.stream(prompt, model: model)
    
    let logger = Logger()
    for try await event in response {
        logger.info("\(String(describing: event))")
    }
}

@Test("testExmaple3")
func testExmaple3() async throws {
    try Dotenv.make()
    
    let client = AsyncHTTPClientTransport(configuration: .init(timeout: .milliseconds(5_000)))
    let session = GPTSession(client: client, retryAdviser: .init(strategy: .init(backOff: .simple(delay: 10_000_000_000))))
    
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
    
    let openai1 = LLMProviderConfiguration(type: .OpenAICompatible, name: "OpenAI", apiKey: Dotenv["OPENAI_API_KEY"]!.stringValue, apiURL: "https://api.openai.com/v1")
    let openai2 = LLMProviderConfiguration(type: .OpenAI, name: "OpenAI", apiKey: Dotenv["OPENAI_API_KEY"]!.stringValue, apiURL: "https://api.openai.com")
    let gpt_4o_1 = LLMModelReference(model: .init(name: "gpt-4o"), provider: openai1)
    let gpt_4o_2 = LLMModelReference(model: .init(name: "gpt-4o"), provider: openai2)
    let response = try await session.stream(prompt, model: .init(name: "gpt-4o", models: [gpt_4o_2, gpt_4o_1]))
    
    let logger = Logger()
    for try await event in response {
        logger.info("\(String(describing: event))")
    }
    
    let response2 = try await session.stream(prompt, model: .init(name: "gpt-4o", models: [gpt_4o_2, gpt_4o_1]))
    for try await event in response2 {
        logger.info("\(String(describing: event))")
    }
}

@Test("testExmaple4")
func testExmaple4() async throws {
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
        ],
        stream: false
    )
    let openai = LLMProviderConfiguration(
        type: .OpenAICompatible,
        name: "OpenAI",
        apiKey: Dotenv["OPENAI_API_KEY"]!.stringValue,
        apiURL: "https://api.openai.com/v1"
    )
    let model = LLMModelReference(model: .init(name: "gpt-4o"), provider: openai)
    let response = try await session.generate(prompt, model: model)
    
    let logger = Logger()
    logger.info("\(String(describing: response))")
}


@Test("testConversationBlock")
func testConversationBlock() async throws {
    try Dotenv.make()
    let client = AsyncHTTPClientTransport()
    let openai = LLMProviderConfiguration(type: .OpenAICompatible, name: "OpenAI", apiKey: Dotenv["OPENAI_API_KEY"]!.stringValue, apiURL: "https://api.openai.com/v1")
    let model = LLMModelReference(model: .init(name: "gpt-4o"), provider: openai)
    
    let session = GPTSession(client: client, conversation: nil)

    do {

        let prompt = Prompt(
            inputs: [
                .text("Hi, I'm John.")
            ],
            stream: false
        )

        let _: ModelResponse = try await session.generate(prompt, model: model)
        #expect(session.conversation != nil)
        #expect(session.conversation?.items.count == 2)
    }

    do {

        let prompt = Prompt(
            inputs: [
                .text("What's my name?")
            ],
            stream: false
        )

        let response: ModelResponse = try await session.generate(prompt, model: model)
        #expect(session.conversation != nil)
        #expect(session.conversation?.items.count == 4)
        #expect(response.message?.text?.contains("John") == true)
        print("response: \(String(describing: response))")
    }
}

@Test("testConversationStream")
func testConversationStream() async throws {
    try Dotenv.make()
    let client = AsyncHTTPClientTransport()
    let openai = LLMProviderConfiguration(
        type: .OpenAICompatible,
        name: "OpenAI",
        apiKey: Dotenv["OPENAI_API_KEY"]!.stringValue,
        apiURL: "https://api.openai.com/v1"
    )
    let gpt4o = LLMModelReference(model: .init(name: "gpt-4o"), provider: openai)
    
    let session = GPTSession(client: client, conversation: nil)

    do {

        let prompt = Prompt(
            inputs: [
                .text("Hi, I'm John.")
            ]
        )

        let stream = try await session.stream(prompt, model: gpt4o)
        for try await event in stream {
            print("event: \(String(describing: event))")
        }
        #expect(session.conversation != nil)
        #expect(session.conversation?.items.count == 2)
    }

    do {

        let prompt = Prompt(
            inputs: [
                .text("What's my name?")
            ]
        )

        let stream = try await session.stream(prompt, model: gpt4o)
        // #expect(response.message?.text?.contains("John") == true)
        for try await event in stream {
            print("event: \(String(describing: event))")
        }
        
        #expect(session.conversation != nil)
        #expect(session.conversation?.items.count == 4)
    }
}

@Test("testConversationSerialization")
func testConversationSerialization() async throws {
    try Dotenv.make()
    let client = AsyncHTTPClientTransport()
    let openai = LLMProviderConfiguration(type: .OpenAICompatible, name: "OpenAI", apiKey: Dotenv["OPENAI_API_KEY"]!.stringValue, apiURL: "https://api.openai.com/v1")
    let model = LLMModelReference(model: .init(name: "gpt-4o"), provider: openai)

    

    let data: Data
    do {

        let prompt = Prompt(
            inputs: [
                .text("Hi, I'm John.")
            ],
            stream: false
        )

        let session = GPTSession(client: client, conversation: nil)
        let _: ModelResponse = try await session.generate(prompt, model: model)
        #expect(session.conversation != nil)
        #expect(session.conversation?.items.count == 2)

        data = try JSONEncoder().encode(session.conversation)
    }

    do {

        let prompt = Prompt(
            inputs: [
                .text("What's my name?")
            ],
            stream: false
        )

        let conversation = try! JSONDecoder().decode(Conversation.self, from: data)
        let session = GPTSession(client: client, conversation: conversation)
        let response: ModelResponse = try await session.generate(prompt, model: model)
        #expect(session.conversation != nil)
        #expect(session.conversation?.items.count == 4)
        #expect(response.message?.text?.contains("John") == true)
        
        print("response: \(String(describing: response))")
    }
}