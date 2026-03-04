//
//  ProviderRequestBodyTests.swift
//  swift-gpt
//
//  Created by Huanan on 2025/10/23.
//

import Foundation
@testable import GPT
import Testing
import LazyKit
import DynamicJSON

@Test
func testOpenAIRequestBodyWithExtraBody() throws {

    let request = OpenAIModelReponseRequest(input: .text("Foo"),
                                            model: "Bar",
                                            background: nil,
                                            include: nil,
                                            instructions: nil,
                                            maxOutputTokens: nil,
                                            metadata: nil,
                                            parallelToolCalls: nil,
                                            previousResponseId: nil,
                                            reasoning: nil,
                                            store: nil,
                                            stream: nil,
                                            temperature: nil,
                                            text: nil,
                                            toolChoice: nil,
                                            tools: nil,
                                            topP: nil,
                                            truncation: nil,
                                            user: nil,
                                            extraBody: [
                                                "baz": ["age":69, "name":"John"]
                                            ])

    let str = "{\"baz\":{\"age\":69,\"name\":\"John\"},\"input\":\"Foo\",\"model\":\"Bar\"}"

    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    let encoded = try encoder.encode(request)
    #expect(String(data: encoded, encoding: .utf8) == str)

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(OpenAIModelReponseRequest.self, from: str.data(using: .utf8)!)
    #expect(decoded.extraBody.debugDescription == request.extraBody.debugDescription)

}

@Test
func testOpenAICompatibleRequestBodyWithExtraBody() throws {

    let request = OpenAIChatCompletionRequest(messages: [],
                                              model: "foo",
                                              audio: nil,
                                              frequencyPenalty: nil,
                                              logitBias: nil,
                                              logprobs: nil,
                                              maxCompletionTokens: nil,
                                              metadata: nil,
                                              modalities: nil,
                                              n: nil,
                                              parallelToolCalls: nil,
                                              prediction: nil,
                                              presencePenalty: nil,
                                              reasoningEffort: nil,
                                              responseFormat: nil,
                                              seed: nil,
                                              serviceTier: nil,
                                              stop: nil,
                                              store: nil,
                                              stream: nil,
                                              streamOptions: nil,
                                              temperature: nil,
                                              toolChoice: nil,
                                              tools: nil,
                                              topLogprobs: nil,
                                              topP: nil,
                                              user: nil,
                                              webSearchOptions: nil,
                                              extraBody: [
                                                "baz": ["age":69, "name":"John"]
                                              ])

    let str = "{\"baz\":{\"age\":69,\"name\":\"John\"},\"messages\":[],\"model\":\"foo\"}"

    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    let encoded = try encoder.encode(request)
    #expect(String(data: encoded, encoding: .utf8) == str)

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(OpenAIChatCompletionRequest.self, from: str.data(using: .utf8)!)
    #expect(decoded.extraBody.debugDescription == request.extraBody.debugDescription)

}


@Test
func testOpenAIRequestBodyWithExtraBodyByAny() throws {

    let str = "{\"baz\":{\"age\":69,\"name\":\"John\"},\"input\":\"Foo\",\"model\":\"Bar\"}"
    let dict: [String: Any] = [
        "input": "Foo",
        "model": "Bar",
        "baz": ["age":69, "name":"John"]
    ]

    let request = try AnyDecoder().decode(OpenAIModelReponseRequest.self, from: dict)

    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    let encoded = try encoder.encode(request)
    #expect(String(data: encoded, encoding: .utf8) == str)

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(OpenAIModelReponseRequest.self, from: str.data(using: .utf8)!)
    #expect(decoded.extraBody.debugDescription == request.extraBody.debugDescription)
}

@Test
func testOpenAICompatibleRequestBodyWithExtraBodyByAny() throws {

    let str = "{\"baz\":{\"age\":69,\"name\":\"John\"},\"messages\":[],\"model\":\"foo\"}"
    let dict: [String: Any] = [
        "messages": [],
        "model": "foo",
        "baz": ["age":69, "name":"John"]
    ]

    let request = try AnyDecoder().decode(OpenAIChatCompletionRequest.self, from: dict)

    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    let encoded = try encoder.encode(request)
    #expect(String(data: encoded, encoding: .utf8) == str)

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(OpenAIChatCompletionRequest.self, from: str.data(using: .utf8)!)
    #expect(decoded.extraBody.debugDescription == request.extraBody.debugDescription)

}
