public struct GenerationError: Codable, Sendable {
    public let code: String?
    public let message: String?
}

public struct GenerationStop: Codable, Sendable {
    public let code: String?
    public let message: String?
}

// MARK: TokenUsage

public struct TokenUsage: Codable, Sendable {
    public let input: Int?
    public let output: Int?
    public let total: Int?
}

// MARK: ResponseItem

public enum ResponseItem: Sendable {
    case message(MessageItem)
}

extension ResponseItem {
    public var message: MessageItem? {
        guard case let .message(value) = self else {
            return nil
        }
        return value
    }
}

// MARK: ResponseItem + Codable

extension ResponseItem: Codable {
    enum CodingKeys: String, CodingKey {
        case type
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(GeneratedContentType.self, forKey: .type)
        switch type {
        case .message:
            self = try .message(.init(from: decoder))
        default:
            throw DecodingError.typeMismatch(MessageItem.self, .init(codingPath: [], debugDescription: "Only Support 'MessageItem'"))
        }
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .message(let messageItem):
            try container.encode(messageItem)
        }
    }
}

// MARK: ResponseContent

public enum ResponseContent: Sendable {
    case text(TextContent)
    case refusal(TextRefusalContent)
}

extension ResponseContent {
    public var text: TextContent? {
        guard case let .text(value) = self else {
            return nil
        }
        return value
    }
    
    public var refusal: TextRefusalContent? {
        guard case let .refusal(value) = self else {
            return nil
        }
        return value
    }
}

// MARK: ResponseContent + Codable

extension ResponseContent: Codable {
    enum CodingKeys: String, CodingKey {
        case type
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(GeneratedContentType.self, forKey: .type)
        switch type {
        case .text:
            self = try .text(.init(from: decoder))
        case .textRefusal:
            self = try .refusal(.init(from: decoder))
        default:
            throw DecodingError.typeMismatch(MessageItem.self, .init(codingPath: [], debugDescription: "Only Support 'MessageItem'"))
        }
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text(let value):
            try container.encode(value)
        case .refusal(let value):
            try container.encode(value)
        }
    }
}

// MARK: ModelResponse

public struct ModelResponse: Codable, Sendable {
    public let id: String?
    
    public let model: String?
    
    public let items: [ResponseItem]

    public let usage: TokenUsage?

    public let stop: GenerationStop?
    public let error: GenerationError?

    public init(id: String?, model: String?, items: [ResponseItem], usage: TokenUsage?, stop: GenerationStop?, error: GenerationError?) {
        self.id = id
        self.model = model
        self.items = items
        self.usage = usage
        self.stop = stop
        self.error = error
    }
}

// MARK: ModelStreamResponse

public enum ModelStreamResponse: Sendable {
    // Response
    case create(Event<ModelResponse?>)
    case completed(Event<ModelResponse>)

    // Item
    case itemAdded(Event<ResponseItem>)
    case itemDone(Event<ResponseItem>)

    // Item.Content
    case contentAdded(Event<ResponseContent>)
    case contentDelta(Event<ResponseContent>) // any PartialUpdatable & GeneratedItem
    case contentDone(Event<ResponseContent>)
}

// MARK: ModelStreamResponse + Event

extension ModelStreamResponse {
    public struct Event<T>: Codable, Sendable where T: Codable & Sendable {
        public let event: EventName
        public let data: T

        public init(event: EventName, data: T) {
            self.event = event
            self.data = data
        }
    }
}

extension ModelStreamResponse.Event: CustomStringConvertible {
    public var description: String {
        "Event('\(event.rawValue)'): \(data)"
    }
}

// MARK: ModelStreamResponse + EventName

extension ModelStreamResponse {
    public struct EventName: RawRepresentable, Hashable, Codable, Sendable {
        public let rawValue: String
        
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }
}

extension ModelStreamResponse.EventName {
    public static let create = Self(rawValue: "response.create")
    public static let completed = Self(rawValue: "response.completed")
    public static let itemAdded = Self(rawValue: "response.item.added")
    public static let itemDone = Self(rawValue: "response.item.done")
    public static let contentAdded = Self(rawValue: "response.item.content.added")
    public static let contentDelta = Self(rawValue: "response.item.content.delta")
    public static let contentDone = Self(rawValue: "response.item.content.done")
}

// MARK: ModelStreamResponse + Codable

extension ModelStreamResponse: Codable {
    enum CodingKeys: String, CodingKey {
        case event
        case data
    }
    
    public init(from decoder: any Decoder) throws {
        let conatiner = try decoder.container(keyedBy: CodingKeys.self)
        let event = try conatiner.decode(EventName.self, forKey: .event)
        
        switch event {
        case .create:
            self = try .create(.init(from: decoder))
        case .completed:
            self = try .completed(.init(from: decoder))
        case .itemAdded:
            self = try .itemAdded(.init(from: decoder))
        case .itemDone:
            self = try .itemDone(.init(from: decoder))
        case .contentAdded:
            self = try .contentAdded(.init(from: decoder))
        case .contentDelta:
            self = try .contentDelta(.init(from: decoder))
        case .contentDone:
            self = try .contentDone(.init(from: decoder))
        default:
            throw DecodingError.typeMismatch(EventName.self, .init(codingPath: [], debugDescription: "Unknown EventName when decode ModelStreamResponse"))
        }
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = try encoder.singleValueContainer()
        switch self {
        case .create(let event):
            try container.encode(event)
        case .completed(let event):
            try container.encode(event)
        case .itemAdded(let event):
            try container.encode(event)
        case .itemDone(let event):
            try container.encode(event)
        case .contentAdded(let event):
            try container.encode(event)
        case .contentDelta(let event):
            try container.encode(event)
        case .contentDone(let event):
            try container.encode(event)
        }
    }
}
