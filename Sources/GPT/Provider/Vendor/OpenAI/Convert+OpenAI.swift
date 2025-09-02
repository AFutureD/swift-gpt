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


extension OpenAIModelReponseContext {
    init?(_ generatedItem: GeneratedItem) {
        switch generatedItem {
        case .message(let message):
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
            }
            return nil
        }

    }
}

extension OpenAIModelReponseRequest {
    init(_ prompt: Prompt, history: Conversation, model: String, stream: Bool) {
        let instructions = prompt.instructions ?? prompt.inputs.compactMap { $0.text }.first { $0.role == .system }?.content
        
        var items: [OpenAIModelReponseRequestInputItem] = []
        for item in history.items {
            switch item {
            case .input(let input):
                let contentItem: OpenAIModelReponseRequestInputItemMessageContentItem
                switch input {
                    case .text(let text):
                        contentItem = .text(.init(text: text.content))
                    case .file(let file):
                        contentItem = .file(.init(fileData: file.content, fileID: file.id, filename: file.filename))
                }
                let content: OpenAIModelReponseContextInput = .init(content: [contentItem], role: .init(rawValue: String(describing: input.role)) ?? .user, status: nil)
                items.append(.output(.input(content)))

            case .generated(let generated):
                if let output: OpenAIModelReponseContext = .init(generated) {
                    items.append(.output(output))
                }
                break
            }
        }

        for input in prompt.inputs {
            switch input.role {
            case .developer:
                if let content: OpenAIModelReponseContextOutputContent = .init(input) {
                    items.append(.output(.output(.init(id: nil, content: [content]))))
                }
            default:
                let content = OpenAIModelReponseRequestInputItemMessageContentItem(input)
                let message: OpenAIModelReponseRequestInputItemMessage = .init(content: .inputs([content]), role: .init(rawValue: input.role.rawValue) ?? .user, type: nil)
                items.append(.message(message))
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
    /// Converts this context into a `GeneratedItem` for the given sequence index.
    /// 
    /// If the context is an `.output`, its content items are converted to `MessageContent` and packaged into a `GeneratedItem.message` with the provided `idx`. If the output has no `id`, a new UUID string is generated and used as the message id. For non-`.output` contexts this returns `nil`.
    /// - Parameter idx: The sequence index to assign to the resulting `MessageItem`.
    /// - Returns: A `GeneratedItem.message` constructed from the context's output, or `nil` if the context is not an output.
    func convert(idx: Int) -> GeneratedItem? {
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
    /// Converts a sequence of `OpenAIModelReponseContext` values into an array of `GeneratedItem`s by calling `convert(idx:)` on each element.
    /// 
    /// The collection is enumerated and each context is converted with its original index; any contexts that fail to convert (return `nil`) are omitted.
    /// - Returns: An array of `GeneratedItem` in the same relative order as the successful conversions.
    func convert() -> [GeneratedItem] {
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
    /// Converts this output content into a `MessageContent` value used by the generated-item pipeline.
    /// - Returns: A `MessageContent` representing the same semantic content:
    ///   - `.text` for `text` content (produces a `TextGeneratedContent` with the text and empty annotations).
    ///   - `.refusal` for `refusal` content (produces a `TextRefusalGeneratedContent`).
    func convertToGenratedItem() -> MessageContent {
        switch self {
        case .text(let text):
            .text(TextGeneratedContent(delta: nil, content: text.text, annotations: []))  // TODO: support annotations
        case .refusal(let refusal):
            .refusal(TextRefusalGeneratedContent(content: refusal.refusal))
        }
    }
}
