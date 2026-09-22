//
//  PrefixCacheTests.swift
//  swift-gpt
//
//  Created by Huanan on 2026/9/22.
//

import Foundation
@testable import GPT
import Testing

private let provider = LLMProviderConfiguration(type: .OpenAI, name: "Ark", apiKey: "key", apiURL: "https://example.com")

private func prompt(system: String = "You are a helpful assistant.", user: String, prefixLength: Int? = 1, thinking: GenerationControl.ThinkingControl? = nil) -> Prompt {
    Prompt(
        inputs: [
            .text(.init(role: .system, content: system)),
            .text(.init(role: .user, content: user)),
        ],
        stream: false,
        generation: .init(temperature: nil, topP: nil, maxTokens: 1024, store: true, thinking: thinking),
        context: .init(cachingPrefixLength: prefixLength)
    )
}

@Test
func testPrefixCacheHashIsOffWithoutPrefixLength() {
    #expect(prompt(user: "a", prefixLength: nil).prefixCacheHashValue == nil)
    #expect(prompt(user: "a", prefixLength: 0).prefixCacheHashValue == nil)
    #expect(prompt(user: "a", prefixLength: nil).prefixCachePrompt == nil)
}

@Test
func testPrefixCacheHashIgnoresTheSuffix() {
    #expect(prompt(user: "a").prefixCacheHashValue == prompt(user: "b").prefixCacheHashValue)
}

@Test
func testPrefixCacheHashChangesWithPrefixOrThinking() {
    let base = prompt(user: "a")
    #expect(base.prefixCacheHashValue != prompt(system: "Be brief.", user: "a").prefixCacheHashValue)
    #expect(base.prefixCacheHashValue != prompt(user: "a", thinking: .init(includeInResponse: nil, level: .high)).prefixCacheHashValue)
}

@Test
func testPrefixCachePromptOnlyHoldsThePrefix() throws {
    let cachePrompt = try #require(prompt(user: "a").prefixCachePrompt)
    #expect(cachePrompt.inputs.count == 1)
    #expect(cachePrompt.inputs.first?.role == .system)
    #expect(cachePrompt.instructions == nil)
    #expect(cachePrompt.stream == false)
    #expect(cachePrompt.context?.cachingPrefixLength == nil)
    #expect(cachePrompt.generation?.maxTokens == nil)
    #expect(cachePrompt.generation?.store == true)
    #expect(cachePrompt.extraBody?["caching"] == ["type": "enabled", "prefix": true])
}

@Test
func testSuffixInputsIsClampedToTheInputs() {
    let p = prompt(user: "a", prefixLength: 5)
    #expect(p.prefixInputs?.count == 2)
    #expect(p.suffixInputs.isEmpty)
}

@Test
func testOpenAIRequestReferencesTheMatchingPrefix() throws {
    let p = prompt(user: "a")
    let hash = try #require(p.prefixCacheHashValue)
    let history = Conversation(
        items: [.input(.text(.init(role: .user, content: "old")))],
        lastReference: .init(name: "Ark", provider: .OpenAI, id: "resp_last"),
        prefixCacheReference: .init(reference: .init(name: "Ark", provider: .OpenAI, id: "resp_prefix"), prefixHashValue: hash)
    )

    let request = OpenAIModelReponseRequest(p, history: history.referencing(provider), model: "m", stream: false)

    #expect(request.previousResponseId == "resp_prefix")
    guard case .items(let items) = request.input else {
        Issue.record("expected items")
        return
    }
    // Only the suffix. Neither the prefix nor the history is sent.
    #expect(items.count == 1)
}

@Test
func testOpenAIRequestFallsBackWhenThePrefixDoesNotMatch() throws {
    let p = prompt(user: "a")
    let history = Conversation(
        items: [.input(.text(.init(role: .user, content: "old")))],
        lastReference: .init(name: "Ark", provider: .OpenAI, id: "resp_last"),
        prefixCacheReference: .init(reference: .init(name: "Ark", provider: .OpenAI, id: "resp_prefix"), prefixHashValue: "stale")
    )

    let request = OpenAIModelReponseRequest(p, history: history.referencing(provider), model: "m", stream: false)

    #expect(request.previousResponseId == "resp_last")
    guard case .items(let items) = request.input else {
        Issue.record("expected items")
        return
    }
    // Falls back to the last response.
    #expect(items.count == 2)
}

@Test
func testOpenAIRequestSendsOnlyTheInputsWithLastReference() throws {
    let p = prompt(user: "a", prefixLength: nil)
    let history = Conversation(
        items: [.input(.text(.init(role: .user, content: "old")))],
        lastReference: .init(name: "Ark", provider: .OpenAI, id: "resp_last")
    )

    let request = OpenAIModelReponseRequest(p, history: history.referencing(provider), model: "m", stream: false)

    #expect(request.previousResponseId == "resp_last")
    guard case .items(let items) = request.input else {
        Issue.record("expected items")
        return
    }
    // Only the inputs.
    #expect(items.count == 2)
}

@Test
func testOpenAIRequestIgnoresReferencesOfOtherProviders() throws {
    let p = prompt(user: "a")
    let hash = try #require(p.prefixCacheHashValue)
    let history = Conversation(
        lastReference: .init(name: "OpenAI", provider: .OpenAI, id: "resp_last"),
        prefixCacheReference: .init(reference: .init(name: "OpenAI", provider: .OpenAI, id: "resp_prefix"), prefixHashValue: hash)
    )

    let request = OpenAIModelReponseRequest(p, history: history.referencing(provider), model: "m", stream: false)

    #expect(request.previousResponseId == nil)
}
