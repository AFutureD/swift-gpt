//
//  ArkContextCacheTests.swift
//  swift-gpt
//
//  Examples of the input patterns of BytePlus ModelArk context cache, Prefix caching and Session caching.
//  The `caching` parameter is not sent, only the shape of the inputs is shown.
//  https://docs.byteplus.com/en/docs/ModelArk/1398933
//

import Foundation
@testable import GPT
import OpenAPIAsyncHTTPClient
import SwiftDotenv
import Testing
import TestKit
import Logging


/// Prefix caching requires at least 256 input tokens.
private let arkCacheContext = """
You are a literary analysis assistant. Use the reference below whenever you answer \
questions about the short story The Gift of the Magi by O. Henry.

Reference:
Della and Jim are a young married couple who live in a cheap furnished flat and have \
almost no spare money. Each of them owns exactly one thing they are proud of. Della has \
long, beautiful hair that falls below her knees. Jim has a gold pocket watch that \
belonged to his father and, before that, to his grandfather.
It is the day before Christmas and Della has managed to save only one dollar and \
eighty-seven cents to buy a present for Jim. After crying and then thinking it over, she \
goes to a hair goods shop and sells her hair for twenty dollars. She spends the money on \
a simple platinum chain for the watch, because Jim has been using an old leather strap \
and is shy about taking the watch out in company.
At home she curls what is left of her hair and waits, worried that Jim will no longer \
find her pretty. When Jim comes in he stares at her in a way she cannot read. He is not \
angry. He hands her a package that holds the set of tortoise shell combs she had wanted \
for a long time, which are useless now that her hair is gone. Della then gives him the \
chain, and Jim admits that he sold the watch to pay for the combs.
The narrator closes by comparing the two of them to the Magi, the wise men who brought \
gifts to the manger, and says that of all who give gifts, these two were the wisest.

Rules:
1. Keep every answer concise.
2. Do not invent events that are not in the reference.
3. Say so plainly when the reference does not contain the requested information.
4. Separate the narrator's warm irony from mockery when you discuss tone.
"""

/// The requirements of explicit cache:
/// 1. `store` must be true.
/// 2. `instructions` must be empty.
/// 3. `thinking` must stay the same across all turns.
/// 4. `stream` can not be true when creating the prefix cache.
private let arkGeneration = GenerationControl(temperature: nil, topP: nil, maxTokens: nil, store: true, thinking: nil)

/// Prefix caching: a fixed prefix with a dynamic suffix.
///
/// The first turn only stores the prefix, with `"caching": {"type": "enabled", "prefix": true}`.
/// Every question references the prefix by `previous_response_id`, and the questions do not see each other.
///
/// - Note: `previous_response_id` comes from `Conversation.lastReference`.
///   The previous turns are still sent by the session for now, so the input tokens are larger than expected.
@Test("testArkPrefixCaching")
func testArkPrefixCaching() async throws {
    try Dotenv.make()
    let client = AsyncHTTPClientTransport()

    let model = LLMModelReference(
        model: "seed-2-0-mini-260428",
        provider: .OpenAI(name: "Ark", apiKey: Dotenv["ARK_API_KEY"]!.stringValue, apiURL: "https://ark.ap-southeast.bytepluses.com/api/v3")
    )
    
    // Create the prefix cache. At least 256 input tokens.
    let prefixSession = GPTSession(client: client, conversation: nil)
    let prefixPrompt = Prompt(
        inputs: [
            .text(.init(role: .system, content: arkCacheContext)),
        ],
        extraBody: [
            "caching": ["type": "enabled", "prefix": true],
            "thinking": ["type": "disabled"],
        ],
        stream: false,
        generation: arkGeneration
    )
    let prefixResponse: ModelResponse = try await prefixSession.generate(prefixPrompt, model: model)
    print("usage: \(String(describing: prefixResponse.usage))")

    // The prefix and the reference of the prefix cache. The prefix cache is never updated.
    let prefix = try #require(prefixSession.conversation)

    let questions = [
        "Write a diary entry from the point of view of Della describing her emotions before selling her hair.",
        "Analyze how O. Henry uses irony in this story. Provide a concise explanation.",
    ]

    for question in questions {
        // Every question branches from the prefix.
        let session = GPTSession(client: client, conversation: prefix)
        let prompt = Prompt(
            inputs: [
                .text(.init(role: .user, content: question)),
            ],
            extraBody: [
                "thinking": ["type": "disabled"],
            ],
            stream: false,
            generation: arkGeneration
        )

        let response: ModelResponse = try await session.generate(prompt, model: model)
        print("responseID: \(session.conversation?.lastReference?.id, default: "nil") usage: \(response.usage, default: "nil")")
    }
}

/// Session caching: the context grows with every turn.
///
/// Every turn enables `"caching": {"type": "enabled"}`, and references the previous turn by `previous_response_id`.
///
/// - Note: `previous_response_id` comes from `Conversation.lastReference`.
///   The previous turns are still sent by the session for now, so the input tokens are larger than expected.
@Test("testArkSessionCaching")
func testArkSessionCaching() async throws {
    try Dotenv.make()
    let client = AsyncHTTPClientTransport()
    let session = GPTSession(client: client, conversation: nil, logger: nil)

    let model = LLMModelReference(
        model: "seed-2-0-mini-260428",
        provider: .OpenAI(name: "Ark", apiKey: Dotenv["ARK_API_KEY"]!.stringValue, apiURL: "https://ark.ap-southeast.bytepluses.com/api/v3")
    )
    
    let turns: [[Prompt.Input]] = [[
        .text(.init(role: .system, content: arkCacheContext)),
        .text("Briefly summarize the story in 5 bullet points."),
    ], [
        .text("Write a diary entry from the point of view of Della describing her emotions before selling her hair."),
    ], [
        .text("Based on the story and the diary Della just wrote, imagine how Jim would feel when he read the diary entry."),
    ]]

    for inputs in turns {
        let prompt = Prompt(
            inputs: inputs,
            extraBody: [
                "caching": ["type": "enabled"], // every turn must enable caching.
                "thinking": ["type": "disabled"],
            ],
            stream: false,
            generation: arkGeneration
        )

        let response: ModelResponse = try await session.generate(prompt, model: model)
        print("responseID: \(session.conversation?.lastReference?.id, default: "nil") usage: \(response.usage, default: "nil")")
    }
}
