//
//  PromptCodableTests.swift
//  swift-gpt
//
//  Created by Huanan on 2025/10/7.
//

import Foundation
@testable import GPT
import Testing

@Test("testInstructionsEncode")
func testInstructionsEncode() async throws {
    let encoder = JSONEncoder()

    do {
        let instruct: Prompt.Instructions = .text("Hi")
        let encoded = try encoder.encode(instruct)
        #expect(String(data: encoded, encoding: .utf8) == "\"Hi\"")
    }

    do {
        let instruct: Prompt.Instructions = .inputs([.text(.init(role: .system, content: "Hi"))])
        let encoded = try encoder.encode(instruct)
        #expect(String(data: encoded, encoding: .utf8) == "[{\"role\":\"system\",\"content\":\"Hi\",\"type\":\"text\"}]")
    }
}

@Test("testInstructionsDecode")
func testInstructionsDecode() async throws {
    let decoder = JSONDecoder()

    do {
        let str = "\"Hi\""
        let decoded = try decoder.decode(Prompt.Instructions.self, from: str.data(using: .utf8)!)
        #expect(decoded == .text("Hi"))
    }

    do {
        let str = "[{\"role\":\"system\",\"content\":\"Hi\",\"type\":\"text\"}]"
        let decoded = try decoder.decode(Prompt.Instructions.self, from: str.data(using: .utf8)!)
        #expect(decoded == .inputs([.text(.init(role: .system, content: "Hi"))]))
    }
}
