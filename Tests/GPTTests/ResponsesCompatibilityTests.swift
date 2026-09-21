import Foundation
@testable import GPT
import Testing

@Suite
struct ResponsesCompatibilityTests {
    private func fixture() throws -> [String: Any] {
        let url = try #require(Bundle.module.url(forResource: "byteplus-response", withExtension: "json"))
        return try #require(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
    }

    private func decode(_ object: [String: Any]) throws -> OpenAIModelReponse {
        try JSONDecoder().decode(OpenAIModelReponse.self, from: JSONSerialization.data(withJSONObject: object))
    }

    private func object<T: Encodable>(_ value: T) throws -> [String: Any] {
        try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(value)) as? [String: Any])
    }

    @Test
    func decodesOmittedOptionalFields() throws {
        // Sanitized real BytePlus response: no metadata, parallel_tool_calls or annotations.
        let response = try decode(fixture())
        #expect(response.metadata == nil)
        #expect(response.parallel_tool_calls == nil)
        let model = ModelResponse(response, nil)
        #expect(model.id == "resp_byteplus_fixture")
        #expect(model.items.first?.message?.content?.first?.text?.content?.contains("101.") == true)
        #expect(model.usage?.cachedInput == 0)
    }

    @Test
    func decodesNullOptionalFields() throws {
        var data = try fixture()
        data["metadata"] = NSNull()
        data["parallel_tool_calls"] = NSNull()
        var output = try #require(data["output"] as? [[String: Any]])
        var content = try #require(output[0]["content"] as? [[String: Any]])
        content[0]["annotations"] = NSNull()
        output[0]["content"] = content
        data["output"] = output
        let response = try decode(data)
        #expect(response.metadata == nil)
        #expect(response.parallel_tool_calls == nil)
        #expect(ModelResponse(response, nil).items.count == 1)
    }

    @Test
    func preservesPresentOptionalFields() throws {
        var data = try fixture()
        data["metadata"] = ["label": "preserved"]
        data["parallel_tool_calls"] = true
        let response = try decode(data)
        #expect(response.metadata == ["label": "preserved"])
        #expect(response.parallel_tool_calls == true)
    }

    @Test(arguments: [0, 566])
    func preservesCachedUsageThroughModelResponseSerialization(cached: Int) throws {
        var data = try fixture()
        var usage = try #require(data["usage"] as? [String: Any])
        usage["input_tokens_details"] = ["cached_tokens": cached]
        data["usage"] = usage
        let model = ModelResponse(try decode(data), nil)
        let roundTrip = try JSONDecoder().decode(ModelResponse.self, from: JSONEncoder().encode(model))
        #expect(roundTrip.usage?.cachedInput == cached)
        #expect(roundTrip.usage?.input == 648)
        #expect(roundTrip.usage?.output == 28)
    }

    @Test
    func decodesLegacyTokenUsageWithoutCacheCount() throws {
        let usage = try JSONDecoder().decode(TokenUsage.self, from: Data(#"{"input":10,"output":2,"total":12}"#.utf8))
        #expect(usage.cachedInput == nil)
        #expect(TokenUsage(input: 10, output: 2, total: 12).cachedInput == nil)
        var data = try fixture()
        data.removeValue(forKey: "usage")
        #expect(ModelResponse(try decode(data), nil).usage?.cachedInput == nil)
    }

    @Test
    func preservesPrefixOnlyResponseIDWithEmptyOutput() throws {
        var data = try fixture()
        data["id"] = "resp_shared_prefix"
        data["output"] = []
        data["usage"] = ["input_tokens": 566, "output_tokens": 0, "total_tokens": 566,
                         "input_tokens_details": ["cached_tokens": 0],
                         "output_tokens_details": ["reasoning_tokens": 0]]
        let model = ModelResponse(try decode(data), nil)
        #expect(model.id == "resp_shared_prefix")
        #expect(model.items.isEmpty)
        #expect(model.usage?.output == 0)
    }

    @Test
    func partialAssistantIsExplicitAndResponsesOnly() throws {
        let partial = TextInputContent(role: .assistant, content: "Translation:", partial: true)
        let roundTrip = try JSONDecoder().decode(TextInputContent.self, from: JSONEncoder().encode(partial))
        #expect(roundTrip.partial == true)
        let prompt = Prompt(inputs: [.text(roundTrip)], stream: false)
        let responses = try object(OpenAIModelReponseRequest(prompt, history: .init(), model: "test", stream: false))
        let input = try #require(responses["input"] as? [[String: Any]])
        #expect(input.last?["partial"] as? Bool == true)
        let chat = try object(OpenAIChatCompletionRequest(prompt, history: .init(), model: "test", stream: false))
        let messages = try #require(chat["messages"] as? [[String: Any]])
        #expect(messages.allSatisfy { $0["partial"] == nil })
    }

    @Test
    func ordinaryAssistantHistoryOmitsPartial() throws {
        let legacy = try JSONDecoder().decode(TextInputContent.self, from: Data(#"{"type":"text","role":"assistant","content":"Earlier reply"}"#.utf8))
        #expect(legacy.partial == nil)
        let prompt = Prompt(inputs: [.text(legacy), .text(.init(role: .user, content: "Continue"))], stream: false)
        let body = try object(OpenAIModelReponseRequest(prompt, history: .init(), model: "test", stream: false))
        let messages = try #require(body["input"] as? [[String: Any]])
        #expect(messages.allSatisfy { $0["partial"] == nil })
        #expect(body["parallel_tool_calls"] as? Bool == false)
    }

    @Test
    func responsesStillIgnoresExtraBodyIncludingCachedResponseID() throws {
        let prompt = Prompt(inputs: [.text(.init(role: .user, content: "Translate"))],
                            extraBody: ["previous_response_id": "resp_root", "caching": ["type": "enabled"]], stream: false)
        let body = try object(OpenAIModelReponseRequest(prompt, history: .init(), model: "test", stream: false))
        #expect(body["previous_response_id"] == nil)
        #expect(body["caching"] == nil)
        #expect(body["parallel_tool_calls"] as? Bool == false)
    }
}
