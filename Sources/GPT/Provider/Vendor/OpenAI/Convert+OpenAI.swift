import Foundation

extension OpenAIModelReponseRequestInputItemMessageContentItem {
    init(_ input: Prompt.Input) {
        switch input {
        case .text(let text):
            self = .text(.init(text: text.content))
        case .file(let file):
            self = .file(.init(fileData: file.content, fileID: file.id, filename: file.filename))
        }
    }
}

extension OpenAIModelReponseContextOutputContent {
    init?(_ input: Prompt.Input) {
        switch input {
        case .text(let text):
            self = .text(.init(annotations: [], text: text.content))
        default:
            return nil
        }
    }
}


extension OpenAIModelReponseRequest {
    init(_ prompt: Prompt, model: String, stream: Bool) {
        let instructions =
            prompt.instructions
            ?? prompt.inputs.compactMap {
                $0.content as? Prompt.Input.TextContent
            }.first {
                $0.role == .system
            }?.content

        let items: [OpenAIModelReponseRequestInputItem] = prompt.inputs.chunked(on: \.content.role).compactMap { role, inputs in
            switch role {
            case .assistant:
                let outputContenxt = inputs.compactMap { OpenAIModelReponseContextOutputContent($0) }
                guard !outputContenxt.isEmpty else { return nil }
                let output = OpenAIModelReponseContextOutput(id: nil, content: outputContenxt)
                return .output(.output(output))
            default:
                let inputItems = inputs.map { OpenAIModelReponseRequestInputItemMessageContentItem($0) }
                let message = OpenAIModelReponseRequestInputItemMessage(content: .inputs(inputItems), role: .init(rawValue: role.rawValue) ?? .user, type: nil)
                return .message(message)
            }
        }
        
        self.init(
            input: .items(items),
            model: model,
            background: nil,  // TODO: suppert backgroud mode.
            include: nil,
            instructions: instructions,
            maxOutputTokens: prompt.maxTokens,
            metadata: nil,
            parallelToolCalls: false,
            previousResponseId: prompt.prev_id,
            reasoning: nil,  // TODO: Add reasning configuration
            store: prompt.store,
            stream: stream,
            temperature: prompt.temperature,
            text: nil,  // TODO: add expected ouput format support
            toolChoice: nil,
            tools: nil,
            topP: prompt.topP,
            truncation: nil,
            user: nil  // TODO: provide session ID or user ID
        )
    }
}

extension OpenAIModelReponseContext {
    func convert(idx: Int) -> ResponseItem? {
        switch self {
        case .output(let output):
            let contents = output.content.map {
                $0.convertToGenratedItem()
            }
            return .message(MessageItem(id: output.id ?? UUID().uuidString, index: idx, content: contents))
        default:
            return nil
        }
    }
}

extension Collection where Element == OpenAIModelReponseContext {
    func convert() -> [ResponseItem] {
        return self.enumerated().compactMap { index, context in
            context.convert(idx: index)
        }
    }
}

extension ModelResponse {
    init(_ response: OpenAIModelReponse) {
        let usage = TokenUsage(
            input: response.usage?.input_tokens,
            output: response.usage?.output_tokens,
            total: response.usage?.total_tokens
        )
        let items = response.output.convert()

        self.init(
            id: response.id,
            model: response.model,
            items: items,
            usage: usage,
            stop: .init(code: nil, message: response.incomplete_details?.reason),
            error: .init(code: response.error?.code, message: response.error?.message))
    }
}

extension ModelStreamResponse {
    init?(_ event: OpenAIModelStreamResponse) {
        switch event {
        case .response_created(_):
            self = .create(.init(event: .create, data: nil))

        case .response_completed(let completed):
            self = .completed(.init(event: .completed, data: ModelResponse(completed.response)))

        case .response_incomplete(let incomplete):
            self = .completed(.init(event: .completed, data: ModelResponse(incomplete.response)))

        case .response_failed(let failed):
            self = .completed(.init(event: .completed, data: ModelResponse(failed.response)))

        case .error(let error):
            self = .completed(.init(event: .completed,
                                    data: ModelResponse(id: nil,
                                                        model: nil,
                                                        items: [],
                                                        usage: nil,
                                                        stop: nil,
                                                        error: .init(code: error.code, message: error.message))))

        case .response_output_item_added(let itemAdded):
            if let item = itemAdded.item.convert(idx: itemAdded.output_index) {
                self = .itemAdded(.init(event: .itemAdded, data: item))
            } else {
                return nil
            }

        case .response_output_item_done(let itemDone):
            if let item = itemDone.item.convert(idx: itemDone.output_index) {
                self = .itemDone(.init(event: .itemDone, data: item))
            } else {
                return nil
            }

        case .response_content_part_added(let partAdded):
            let content = partAdded.part.convertToGenratedItem()
            self = .contentAdded(.init(event: .contentAdded, data: content))

        case .response_content_part_done(let partDone):
            let content = partDone.part.convertToGenratedItem()
            self = .contentDone(.init(event: .contentDone, data: content))

        case .response_output_text_delta(let textDelta):
            let content = TextGeneratedContent(delta: textDelta.delta, content: nil, annotations: [])
            self = .contentDelta(.init(event: .contentDelta, data: .text(content)))

        default:
            return nil
        }
    }
}

extension OpenAIModelReponseContextOutputContent {
    func convertToGenratedItem() -> ResponseContent {
        switch self {
        case .text(let text):
            .text(TextGeneratedContent(delta: nil, content: text.text, annotations: []))  // TODO: support annotations
        case .refusal(let refusal):
            .refusal(TextRefusalGeneratedContent(content: refusal.refusal))
        }
    }
}
