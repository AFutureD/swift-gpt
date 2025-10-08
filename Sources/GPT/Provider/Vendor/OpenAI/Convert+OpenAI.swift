import Foundation

extension OpenAIModelReponseRequestInputItemMessageContentItem {
    init?(_ input: Prompt.Input) {
        switch input {
        case let .text(text):
            self = .text(.init(text: text.content))
        case let .file(file):
            self = .file(.init(fileData: file.content, fileID: file.id, filename: file.filename))
        }
    }
}

extension OpenAIModelReponseContextOutputContent {
    init?(_ input: Prompt.Input) {
        switch input {
        case let .text(text):
            self = .text(.init(annotations: [], text: text.content))
        default:
            return nil
        }
    }
}

extension OpenAIModelReponseContext {
    init?(_ generatedItem: GeneratedItem) {
        switch generatedItem {
        case let .message(message):
            var content: [OpenAIModelReponseContextOutputContent] = []
            if let refusal = message.refusalContent, let text = refusal.content {
                content.append(.refusal(.init(refusal: text)))
                self = .output(.init(id: String(describing: message.id), content: content))
                return
            }
            if let textContents = message.textContents {
                for textContent in textContents {
                    if let text = textContent.content {
                        content.append(.text(.init(annotations: [], text: text)))
                    }
                }
                self = .output(.init(id: String(describing: message.id), content: content))
                return
            }
            return nil
        }
    }
}

private func convert(inputs: [Prompt.Input]) -> [OpenAIModelReponseRequestInputItem] {
    var items: [OpenAIModelReponseRequestInputItem] = []
    for input in inputs {
        switch input.role {
        case .assistant:
            if let content: OpenAIModelReponseContextOutputContent = .init(input) {
                items.append(.output(.output(.init(id: nil, content: [content]))))
            }
        default:
            if let content = OpenAIModelReponseRequestInputItemMessageContentItem(input) {
                let message: OpenAIModelReponseRequestInputItemMessage = .init(content: .inputs([content]), role: .init(rawValue: input.role.rawValue) ?? .user, type: nil)
                items.append(.message(message))
            }
        }
    }
    return items
}

private func convert(conversationItems: [ConversationItem]) -> [OpenAIModelReponseRequestInputItem] {
    var items: [OpenAIModelReponseRequestInputItem] = []
    for item in conversationItems {
        switch item {
        case let .input(input):
            if let content = OpenAIModelReponseRequestInputItemMessageContentItem(input) {
                let input: OpenAIModelReponseContextInput = .init(content: [content], role: .init(rawValue: String(describing: input.role)) ?? .user, status: nil)
                items.append(.output(.input(input)))
            }

        case let .generated(generated):
            if let output: OpenAIModelReponseContext = .init(generated) {
                items.append(.output(output))
            }
        }
    }
    return items
}

extension OpenAIModelReponseRequest {
    init(_ prompt: Prompt, history: Conversation, model: String, stream: Bool) {
        let instructions = prompt.instructions?.text ?? prompt.inputs.compactMap { $0.text }.first { $0.role == .system }?.content
        var items: [OpenAIModelReponseRequestInputItem] = []

        if history.items.isEmpty {
            if case let .inputs(inputs) = prompt.instructions {
                items.append(contentsOf: convert(inputs: inputs))
            }
        }

        items.append(contentsOf: convert(conversationItems: history.items))
        items.append(contentsOf: convert(inputs: prompt.inputs))

        self.init(
            input: .items(items),
            model: model,
            background: nil, // TODO: suppert backgroud mode.
            include: nil,
            instructions: instructions,
            maxOutputTokens: prompt.generation?.maxTokens,
            metadata: nil,
            parallelToolCalls: false,
            previousResponseId: nil,
            reasoning: nil, // TODO: Add reasning configuration
            store: prompt.generation?.store,
            stream: stream,
            temperature: prompt.generation?.temperature,
            text: nil, // TODO: add expected ouput format support
            toolChoice: nil,
            tools: nil,
            topP: prompt.generation?.topP,
            truncation: nil,
            user: nil // TODO: provide session ID or user ID
        )
    }
}

extension OpenAIModelReponseContext {
    func convert(idx: Int) -> GeneratedItem? {
        switch self {
        case let .output(output):
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
    func convert() -> [GeneratedItem] {
        return enumerated().compactMap { index, context in
            context.convert(idx: index)
        }
    }
}

extension ModelResponse {
    init(_ response: OpenAIModelReponse, _ context: GenerationConext?) {
        let usage = TokenUsage(
            input: response.usage?.input_tokens,
            output: response.usage?.output_tokens,
            total: response.usage?.total_tokens
        )
        let items = response.output.convert()

        self.init(
            id: response.id,
            context: context,
            model: response.model,
            items: items,
            usage: usage,
            stop: .init(code: nil, message: response.incomplete_details?.reason),
            error: .init(code: response.error?.code, message: response.error?.message)
        )
    }
}

extension ModelStreamResponse {
    init?(_ event: OpenAIModelStreamResponse, _ context: GenerationConext?) {
        switch event {
        case .response_created:
            self = .create(.init(event: .create, data: nil))

        case let .response_completed(completed):
            self = .completed(.init(event: .completed, data: ModelResponse(completed.response, context)))

        case let .response_incomplete(incomplete):
            self = .completed(.init(event: .completed, data: ModelResponse(incomplete.response, context)))

        case let .response_failed(failed):
            self = .completed(.init(event: .completed, data: ModelResponse(failed.response, context)))

        case let .error(error):
            self = .completed(.init(event: .completed,
                                    data: ModelResponse(id: nil,
                                                        context: context,
                                                        model: nil,
                                                        items: [],
                                                        usage: nil,
                                                        stop: nil,
                                                        error: .init(code: error.code, message: error.message))))

        case let .response_output_item_added(itemAdded):
            if let item = itemAdded.item.convert(idx: itemAdded.output_index) {
                self = .itemAdded(.init(event: .itemAdded, data: item))
            } else {
                return nil
            }

        case let .response_output_item_done(itemDone):
            if let item = itemDone.item.convert(idx: itemDone.output_index) {
                self = .itemDone(.init(event: .itemDone, data: item))
            } else {
                return nil
            }

        case let .response_content_part_added(partAdded):
            let content = partAdded.part.convertToGenratedItem()
            self = .contentAdded(.init(event: .contentAdded, data: content))

        case let .response_content_part_done(partDone):
            let content = partDone.part.convertToGenratedItem()
            self = .contentDone(.init(event: .contentDone, data: content))

        case let .response_output_text_delta(textDelta):
            let content = TextGeneratedContent(delta: textDelta.delta, content: nil, annotations: [])
            self = .contentDelta(.init(event: .contentDelta, data: .text(content)))

        default:
            return nil
        }
    }
}

extension OpenAIModelReponseContextOutputContent {
    func convertToGenratedItem() -> MessageContent {
        switch self {
        case let .text(text):
            .text(TextGeneratedContent(delta: nil, content: text.text, annotations: [])) // TODO: support annotations
        case let .refusal(refusal):
            .refusal(TextRefusalGeneratedContent(content: refusal.refusal))
        }
    }
}
