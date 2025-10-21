//
//  OpenAIModelReponseRequest.swift
//  swift-workflow
//
//  Created by AFuture on 2025/5/6.
//

@preconcurrency import DynamicJSON
import Foundation
import HTTPTypes
import LazyKit

/// https://platform.openai.com/docs/guides/pdf-files?api-mode=chat
public struct OpenAIModelReponseRequestInputItemMessageContentItemFileInput: Codable, Sendable {
    public let type: OpenAIModelReponseRequestInputItemMessageContentType

    /// The content of the file to be sent to the model.
    public let fileData: String?

    /// The ID of the file to be sent to the model.
    public let fileID: String?

    /// The name of the file to be sent to the model.
    public let filename: String?

    enum CodingKeys: String, CodingKey {
        case type
        case fileData = "file_data"
        case fileID = "file_id"
        case filename
    }

    init(fileData: String?, fileID: String?, filename: String?) {
        self.type = .file
        self.fileData = fileData
        self.fileID = fileID
        self.filename = filename
    }
}

/// The detail level of the image to be sent to the model. One of high, low, or auto. Defaults to auto.
public enum OpenAIModelReponseRequestInputItemMessageContentImageItemDetail: String, Codable, Sendable {
    case high
    case low
    case auto

    // static let `default`: Self = .auto
}

/// An image input to the model.
/// Learn about [image inputs](https://platform.openai.com/docs/guides/images?api-mode=responses).
public struct OpenAIModelReponseRequestInputItemMessageContentItemImageInput: Codable, Sendable {
    public let type: OpenAIModelReponseRequestInputItemMessageContentType

    public let detail: OpenAIModelReponseRequestInputItemMessageContentImageItemDetail

    // The ID of the file to be sent to the model.
    public let fileId: String?

    // The URL of the image to be sent to the model.
    // A fully qualified URL or base64 encoded image in a data URL.
    public let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case type
        case detail
        case fileId = "file_id"
        case imageUrl = "image_url"
    }

    init(detail: OpenAIModelReponseRequestInputItemMessageContentImageItemDetail, fileId: String?, imageUrl: String?) {
        self.type = .image
        self.detail = detail
        self.fileId = fileId
        self.imageUrl = imageUrl
    }
}

public struct OpenAIModelReponseRequestInputItemMessageContentItemTextInput: Codable, Sendable {
    public let text: String
    public let type: OpenAIModelReponseRequestInputItemMessageContentType

    init(text: String) {
        self.text = text
        self.type = .text
    }
}

public enum OpenAIModelReponseRequestInputItemMessageContentType: String, Codable, Sendable {
    case text = "input_text"
    case image = "input_image"
    case file = "input_file"
}

/// A list of one or many input items to the model, containing different content types.
public enum OpenAIModelReponseRequestInputItemMessageContentItem: Codable, Sendable {
    case text(OpenAIModelReponseRequestInputItemMessageContentItemTextInput)
    case image(OpenAIModelReponseRequestInputItemMessageContentItemImageInput)
    case file(OpenAIModelReponseRequestInputItemMessageContentItemFileInput)

    public enum CodingKeys: String, CodingKey {
        case type
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text(let modelReponseRequestInputItemMessageContentItemTextInput):
            try container.encode(modelReponseRequestInputItemMessageContentItemTextInput)
        case .image(let modelReponseRequestInputItemMessageContentItemImageInput):
            try container.encode(modelReponseRequestInputItemMessageContentItemImageInput)
        case .file(let modelReponseRequestInputItemMessageContentItemFileInput):
            try container.encode(modelReponseRequestInputItemMessageContentItemFileInput)
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let type = try container.decode(OpenAIModelReponseRequestInputItemMessageContentType.self, forKey: .type)
        switch type {
        case .text:
            self = try .text(.init(from: decoder))
        case .image:
            self = try .image(.init(from: decoder))
        case .file:
            self = try .file(.init(from: decoder))
        }
    }
}

public enum OpenAIModelReponseRequestInputItemMessageContent: Codable, Sendable {
    case text(String)
    case inputs([OpenAIModelReponseRequestInputItemMessageContentItem])

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text(let a0):
            try container.encode(a0)
        case .inputs(let a0):
            try container.encode(a0)
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let stringValue = try? container.decode(String.self) {
            self = .text(stringValue)
            return
        }

        if let itemArray = try? container.decode([OpenAIModelReponseRequestInputItemMessageContentItem].self) {
            self = .inputs(itemArray)
            return
        }

        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode ModelReponseRequestInputItemMessageContent")
    }
}

public enum OpenAIModelReponseRequestInputItemMessageRole: String, Codable, Sendable {
    case user
    case assistant
    case system
    case developer
}

/// A message input to the model with a role indicating instruction following hierarchy.
/// Instructions given with the developer or system role take precedence over instructions given with the user role.
/// Messages with the assistant role are presumed to have been generated by the model in previous interactions.
public struct OpenAIModelReponseRequestInputItemMessage: Codable, Sendable {
    /// Text, image, or audio input to the model, used to generate a response. Can also contain previous assistant responses.
    public let content: OpenAIModelReponseRequestInputItemMessageContent

    /// The role of the message input. One of user, assistant, system, or developer.
    public let role: OpenAIModelReponseRequestInputItemMessageRole

    public let type: ModelReponseRequestInputItemType?
}

/// Populated when items are returned via API.
public enum OpenAIModelReponseContextInputStatus: String, Codable, Sendable {
    case inProgress = "in_progress"
    case completed
    case incomplete
}

public enum OpenAIModelReponseContextInputRole: String, Codable, Sendable {
    case user
    case system
    case developer
}

/// A citation to a file.
public struct OpenAIModelReponseContextOutputContentTextOutputAnnotationFileCitation: Codable, Sendable {
    let fileId: String
    let index: Int
    let type: OpenAIModelReponseContextOutputContentTextOutputAnnotationType = .file_citation

    public enum CodingKeys: String, CodingKey {
        case fileId = "file_id"
        case index
        case type
    }
}

/// A citation for a web resource used to generate a model response.
public struct OpenAIModelReponseContextOutputContentTextOutputAnnotationURLCitation: Codable, Sendable {
    let endIndex: Int
    let startIndex: Int
    let title: String
    let url: String
    let type: OpenAIModelReponseContextOutputContentTextOutputAnnotationType = .url_citation

    public enum CodingKeys: String, CodingKey {
        case endIndex = "end_index"
        case startIndex = "start_index"
        case title
        case url
        case type
    }
}

/// A path to a file.
public struct OpenAIModelReponseContextOutputContentTextOutputAnnotationFilePath: Codable, Sendable {
    let fileId: String
    let index: Int
    let type: OpenAIModelReponseContextOutputContentTextOutputAnnotationType = .file_path

    public enum CodingKeys: String, CodingKey {
        case fileId = "file_id"
        case index
        case type
    }
}

public enum OpenAIModelReponseContextOutputContentTextOutputAnnotationType: String, Codable, Sendable {
    case file_citation
    case url_citation
    case file_path
}

public enum OpenAIModelReponseContextOutputContentTextOutputAnnotation: Codable, Sendable {
    case fileCitation(OpenAIModelReponseContextOutputContentTextOutputAnnotationFileCitation)
    case url(OpenAIModelReponseContextOutputContentTextOutputAnnotationURLCitation)
    case filePath(OpenAIModelReponseContextOutputContentTextOutputAnnotationFilePath)

    public enum CodingKeys: String, CodingKey {
        case type
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .fileCitation(let a0):
            try container.encode(a0)
        case .url(let a0):
            try container.encode(a0)
        case .filePath(let a0):
            try container.encode(a0)
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let type = try container.decode(OpenAIModelReponseContextOutputContentTextOutputAnnotationType.self, forKey: .type)
        switch type {
        case .file_citation:
            self = try .fileCitation(.init(from: decoder))
        case .url_citation:
            self = try .url(.init(from: decoder))
        case .file_path:
            self = try .filePath(.init(from: decoder))
        }
    }
}

// A text output from the model.
public struct OpenAIModelReponseContextOutputContentTextOutput: Codable, Sendable {
    let annotations: [OpenAIModelReponseContextOutputContentTextOutputAnnotation]
    let text: String
    let type: OpenAIModelReponseContextOutputContentType = .output_text

    public enum CodingKeys: String, CodingKey {
        case annotations
        case text
        case type
    }
}

// The refusal explanation from the model.
public struct OpenAIModelReponseContextOutputContentRefusal: Codable, Sendable {
    let refusal: String
    let type: OpenAIModelReponseContextOutputContentType = .refusal

    public enum CodingKeys: String, CodingKey {
        case refusal
        case type
    }
}

public enum OpenAIModelReponseContextOutputContentType: String, Codable, Sendable {
    case output_text
    case refusal
}

public enum OpenAIModelReponseContextOutputContent: Codable, Sendable {
    case text(OpenAIModelReponseContextOutputContentTextOutput)
    case refusal(OpenAIModelReponseContextOutputContentRefusal)

    public enum CodingKeys: String, CodingKey {
        case type
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text(let a0):
            try container.encode(a0)
        case .refusal(let a0):
            try container.encode(a0)
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let type = try container.decode(OpenAIModelReponseContextOutputContentType.self, forKey: .type)
        switch type {
        case .output_text:
            self = try .text(.init(from: decoder))
        case .refusal:
            self = try .refusal(.init(from: decoder))
        }
    }
}

public struct OpenAIModelReponseContextOutput: Codable, Sendable {
    /// The unique ID of the output message.
    let id: String?
    let content: [OpenAIModelReponseContextOutputContent]
    let role: String = "assistant"
    let type: OpenAIModelReponseContextType = .message

    enum CodingKeys: String, CodingKey {
        case id
        case content
        case role
        case type
    }
}

/// A message input to the model with a role indicating instruction following hierarchy.
/// Instructions given with the developer or system role take precedence over instructions given with the user role.
public struct OpenAIModelReponseContextInput: Codable, Sendable {
    let content: [OpenAIModelReponseRequestInputItemMessageContentItem]
    let role: OpenAIModelReponseContextInputRole
    let status: OpenAIModelReponseContextInputStatus?
    let type: OpenAIModelReponseContextType

    init(
        content: [OpenAIModelReponseRequestInputItemMessageContentItem],
        role: OpenAIModelReponseContextInputRole,
        status: OpenAIModelReponseContextInputStatus?
    ) {
        self.content = content
        self.role = role
        self.status = status
        self.type = .message
    }
}

public enum OpenAIModelReponseContextWebSearchToolCallStatus: String, Codable, Sendable {
    case inProgress = "in_progress"
    case searching
    case incomplete
    case failed
}

// The queries used to search for files.
public typealias OpenAIModelReponseContextFileSearchToolCallResultQuery = String

public struct OpenAIModelReponseContextFileSearchToolCallResult: Codable, Sendable {
    /// Set of 16 key-value pairs that can be attached to an object.
    /// This can be useful for storing additional information about the object in a structured format,
    /// and querying for objects via API or the dashboard.
    /// Keys are strings with a maximum length of 64 characters.
    /// Values are strings with a maximum length of 512 characters, booleans, or numbers.
    let attributes: [String: String]?
    let fileId: String?
    let filename: String?
    let score: Double?
    let text: String?

    enum CodingKeys: String, CodingKey {
        case attributes
        case fileId = "file_id"
        case filename
        case score
        case text
    }
}

/// The queries used to [search for files](https://platform.openai.com/docs/guides/tools-file-search).
public struct OpenAIModelReponseContextFileSearchToolCall: Codable, Sendable {
    let id: String
    let queries: [OpenAIModelReponseContextFileSearchToolCallResultQuery]
    let status: OpenAIModelReponseContextWebSearchToolCallStatus
    let type: OpenAIModelReponseContextType = .file_search_call
    let results: [OpenAIModelReponseContextFileSearchToolCallResult]?

    public enum CodingKeys: String, CodingKey {
        case id
        case queries
        case status
        case type
        case results
    }
}

public enum ModelReponseRequestInputItemContextComputerToolCallActionClickButton: String, Codable, Sendable {
    case left
    case right
    case wheel
    case back
    case forward
}

public struct OpenAIModelReponseContextComputerToolCallActionActionClick: Codable, Sendable {
    let button: ModelReponseRequestInputItemContextComputerToolCallActionClickButton
    let type: OpenAIModelReponseContextComputerToolCallActionType = .click
    let x: Int
    let y: Int

    public enum CodingKeys: String, CodingKey {
        case button
        case type
        case x
        case y
    }
}

public struct OpenAIModelReponseContextComputerToolCallActionDoubleClick: Codable, Sendable {
    let type: OpenAIModelReponseContextComputerToolCallActionType = .double_click
    let x: Int
    let y: Int

    public enum CodingKeys: String, CodingKey {
        case type
        case x
        case y
    }
}

public struct OpenAIModelReponseContextComputerToolCallActionDragCoordinate: Codable, Sendable {
    let x: Int
    let y: Int
}

public struct OpenAIModelReponseContextComputerToolCallActionDrag: Codable, Sendable {
    let type = "drag"
    /// An array of coordinates representing the path of the drag action. Coordinates will appear as an array of objects.
    let path: [OpenAIModelReponseContextComputerToolCallActionDragCoordinate]

    public enum CodingKeys: String, CodingKey {
        case type
        case path
    }
}

/// A collection of keypresses the model would like to perform.
public struct OpenAIModelReponseContextComputerToolCallActionKeyPress: Codable, Sendable {
    let type: OpenAIModelReponseContextComputerToolCallActionType = .keypress
    /// The combination of keys the model is requesting to be pressed. This is an array of strings, each representing a key.
    let keys: [String]

    public enum CodingKeys: String, CodingKey {
        case type
        case keys
    }
}

/// A mouse move action.
public struct OpenAIModelReponseContextComputerToolCallActionMove: Codable, Sendable {
    let type: OpenAIModelReponseContextComputerToolCallActionType = .move
    /// The x-coordinate to move to.
    let x: Int
    /// The y-coordinate to move to.
    let y: Int

    public enum CodingKeys: String, CodingKey {
        case type
        case x
        case y
    }
}

/// A screenshot action.
public struct OpenAIModelReponseContextComputerToolCallActionScreenshot: Codable, Sendable {
    let type: OpenAIModelReponseContextComputerToolCallActionType = .screenshot

    public enum CodingKeys: String, CodingKey {
        case type
    }
}

/// A scroll action.
public struct OpenAIModelReponseContextComputerToolCallActionScroll: Codable, Sendable {
    let type: OpenAIModelReponseContextComputerToolCallActionType = .scroll
    /// The horizontal scroll distance.
    let scrollX: Int
    /// The vertical scroll distance.
    let scrollY: Int
    /// The x-coordinate where the scroll occurred.
    let x: Int
    /// The y-coordinate where the scroll occurred.
    let y: Int

    public enum CodingKeys: String, CodingKey {
        case type
        case scrollX = "scroll_x"
        case scrollY = "scroll_y"
        case x
        case y
    }
}

/// An action to type in text.
public struct OpenAIModelReponseContextComputerToolCallActionTypeText: Codable, Sendable {
    let text: String
    let type: OpenAIModelReponseContextComputerToolCallActionType = .type

    public enum CodingKeys: String, CodingKey {
        case text
        case type
    }
}

/// A wait action.
public struct OpenAIModelReponseContextComputerToolCallActionWait: Codable, Sendable {
    let type: OpenAIModelReponseContextComputerToolCallActionType = .wait

    public enum CodingKeys: String, CodingKey {
        case type
    }
}

public enum OpenAIModelReponseContextComputerToolCallActionType: String, Codable, Sendable {
    case click
    case double_click
    case drag
    case keypress
    case move
    case screenshot
    case scroll
    case type
    case wait
}

public enum OpenAIModelReponseContextComputerToolCallAction: Codable, Sendable {
    case click(OpenAIModelReponseContextComputerToolCallActionActionClick)
    case doubleClick(OpenAIModelReponseContextComputerToolCallActionDoubleClick)
    case drag(OpenAIModelReponseContextComputerToolCallActionDrag)
    case keyPress(OpenAIModelReponseContextComputerToolCallActionKeyPress)
    case move(OpenAIModelReponseContextComputerToolCallActionMove)
    case screenshot(OpenAIModelReponseContextComputerToolCallActionScreenshot)
    case scroll(OpenAIModelReponseContextComputerToolCallActionScroll)
    case type(OpenAIModelReponseContextComputerToolCallActionTypeText)
    case wait(OpenAIModelReponseContextComputerToolCallActionWait)

    public enum CodingKeys: String, CodingKey {
        case type
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .click(let click):
            try container.encode(click)
        case .doubleClick(let doubleClick):
            try container.encode(doubleClick)
        case .drag(let drag):
            try container.encode(drag)
        case .keyPress(let keyPress):
            try container.encode(keyPress)
        case .move(let move):
            try container.encode(move)
        case .screenshot(let screenshot):
            try container.encode(screenshot)
        case .scroll(let scroll):
            try container.encode(scroll)
        case .type(let type):
            try container.encode(type)
        case .wait(let wait):
            try container.encode(wait)
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let type = try container.decode(OpenAIModelReponseContextComputerToolCallActionType.self, forKey: .type)
        switch type {
        case .click:
            self = try .click(.init(from: decoder))
        case .double_click:
            self = try .doubleClick(.init(from: decoder))
        case .drag:
            self = try .drag(.init(from: decoder))
        case .keypress:
            self = try .keyPress(.init(from: decoder))
        case .move:
            self = try .move(.init(from: decoder))
        case .screenshot:
            self = try .screenshot(.init(from: decoder))
        case .scroll:
            self = try .scroll(.init(from: decoder))
        case .type:
            self = try .type(.init(from: decoder))
        case .wait:
            self = try .wait(.init(from: decoder))
        }
    }
}

/// The pending safety checks for the computer call.
public struct ModelReponseRequestInputItemContextComputerToolCallSafetyCheck: Codable, Sendable {
    // The type of the pending safety check.
    let code: String
    // The ID of the pending safety check.
    let id: String
    // Details about the pending safety check.
    let message: String
}

public enum ModelReponseRequestInputItemContextComputerToolCallStatus: Codable, Sendable {
    case in_progress
    case completed
    case incomplete
}

/// A tool call to a computer use tool. See the [computer use guide](https://platform.openai.com/docs/guides/tools-computer-use) for more information.
public struct OpenAIModelReponseContextComputerToolCallRequest: Codable, Sendable {
    let action: OpenAIModelReponseContextComputerToolCallAction
    /// An identifier used when responding to the tool call with output.
    let callId: String
    /// The unique ID of the computer call.
    let id: String
    let pendingSafetyChecks: [ModelReponseRequestInputItemContextComputerToolCallSafetyCheck]
    let status: ModelReponseRequestInputItemContextComputerToolCallStatus
    let type: OpenAIModelReponseContextType = .computer_call

    public enum CodingKeys: String, CodingKey {
        case action
        case callId = "call_id"
        case id
        case pendingSafetyChecks = "pending_safety_checks"
        case status
        case type
    }
}

public enum ModelReponseRequestInputItemContextComputerToolCallOutputStatus: String, Codable, Sendable {
    case in_progress
    case completed
    case incomplete
}

public struct ModelReponseRequestInputItemContextComputerToolCallOutputObject: Codable, Sendable {
    let type: String = "computer_screenshot"
    /// The identifier of an uploaded file that contains the screenshot.
    let fileId: String?
    /// The URL of the screenshot image.
    let imageUrl: String?

    public enum CodingKeys: String, CodingKey {
        case type
        case fileId = "file_id"
        case imageUrl = "image_url"
    }
}

/// The output of a computer tool call.
public struct OpenAIModelReponseContextComputerToolCallReponse: Codable, Sendable {
    let type: OpenAIModelReponseContextType = .computer_call_output
    /// The ID of the computer tool call that produced the output.
    let callId: String
    /// The ID of the computer tool call output.
    let id: String?
    /// The status of the message input. Populated when input items are returned via API.
    let status: ModelReponseRequestInputItemContextComputerToolCallOutputStatus?
    /// A computer screenshot image used with the computer use tool.
    let output: ModelReponseRequestInputItemContextComputerToolCallOutputObject
    /// The safety checks reported by the API that have been acknowledged by the developer.
    let acknowledgeSafetyChecks: [ModelReponseRequestInputItemContextComputerToolCallSafetyCheck]?

    public enum CodingKeys: String, CodingKey {
        case type
        case callId = "call_id"
        case id
        case status
        case output
        case acknowledgeSafetyChecks = "acknowledge_safety_checks"
    }
}

/// The results of a web search tool call. See the [web search guide](https://platform.openai.com/docs/guides/tools-web-search) for more information.
public struct OpenAIModelReponseContextWebSearchToolCall: Codable, Sendable {
    let id: String
    let status: OpenAIModelReponseContextWebSearchToolCallStatus
    let type: OpenAIModelReponseContextType = .web_search_call

    public enum CodingKeys: String, CodingKey {
        case id
        case status
        case type
    }
}

public enum OpenAIModelReponseContextFuncToolCallStatus: Codable, Sendable {
    case in_progress
    case completed
    case incomplete
}

/// A tool call to run a function.
/// See the [function calling](https://platform.openai.com/docs/guides/function-calling?api-mode=responses) guide for more information.
public struct OpenAIModelReponseContextFuncToolCall: Codable, Sendable {
    /// A JSON string of the arguments to pass to the function.
    let arguments: String

    /// The unique ID of the function tool call generated by the model.
    let callId: String

    /// The name of the function to run.
    let name: String

    let type: OpenAIModelReponseContextType = .function_call

    /// The unique ID of the function tool call.
    let id: String?

    let status: OpenAIModelReponseContextFuncToolCallStatus?

    public enum CodingKeys: String, CodingKey {
        case arguments
        case callId = "call_id"
        case name
        case type
        case id
        case status
    }
}

public enum OpenAIModelReponseContextFuncToolCallOutputStatus: Codable, Sendable {
    case in_progress
    case completed
    case incomplete
}

/// The output of a function tool call.
public struct OpenAIModelReponseContextFuncToolCallOutput: Codable, Sendable {
    /// The unique ID of the function tool call generated by the model.
    let callId: String

    /// A JSON string of the output of the function tool call.
    let output: String

    let type: OpenAIModelReponseContextType = .function_call_output

    /// The unique ID of the function tool call output. Populated when this item is returned via API.
    let id: String?

    /// The status of the item. Populated when items are returned via API.
    let status: OpenAIModelReponseContextFuncToolCallOutputStatus?

    public enum CodingKeys: String, CodingKey {
        case callId = "call_id"
        case output
        case type
        case id
        case status
    }
}

public enum OpenAIModelReponseContextReasoningStatus: Codable, Sendable {
    case in_progress
    case completed
    case incomplete
}

/// Reasoning text contents.
public struct OpenAIModelReponseContextReasoningSummaryTextContent: Codable, Sendable {
    let type: String = "summary_text"
    /// A short summary of the reasoning used by the model when generating the
    let text: String

    public enum CodingKeys: String, CodingKey {
        case type
        case text
    }
}

public struct OpenAIModelReponseContextReasoning: Codable, Sendable {
    let id: String
    let summary: [OpenAIModelReponseContextReasoningSummaryTextContent]
    let type: OpenAIModelReponseContextType = .reasoning
    /// The status of the item. Populated when items are returned via API.
    let status: OpenAIModelReponseContextReasoningStatus?

    public enum CodingKeys: String, CodingKey {
        case id
        case summary
        case type
        case status
    }
}

/// An image generation request made by the model.
public struct OpenAIModelReponseContextImageGeneration: Codable, Sendable {
    /// The unique ID of the image generation call.
    let id: String
    /// The generated image encoded in base64.
    let result: String
    /// The status of the image generation call.
    let status: String
    let type: OpenAIModelReponseContextType = .image_generation_call

    enum CodingKeys: CodingKey {
        case id
        case result
        case status
        case type
    }
}

public struct OpenAIModelReponseContextCodeInterpreterResultTextOutput: Codable, Sendable {
    let logs: String
    let type: String = "logs"

    enum CodingKeys: CodingKey {
        case logs
        case type
    }
}

public struct OpenAIModelReponseContextCodeInterpreterResultFileOutputFile: Codable, Sendable {
    let file_id: String
    let mime_type: String
}

public struct OpenAIModelReponseContextCodeInterpreterResultFileOutput: Codable, Sendable {
    let files: [OpenAIModelReponseContextCodeInterpreterResultFileOutputFile]
    let type: String = "files"

    enum CodingKeys: CodingKey {
        case files
        case type
    }
}

public enum OpenAIModelReponseContextCodeInterpreterResult: Codable, Sendable {
    case text(OpenAIModelReponseContextCodeInterpreterResultTextOutput)
    case file(OpenAIModelReponseContextCodeInterpreterResultFileOutput)
}

/// A tool call to run code.
public struct OpenAIModelReponseContextCodeInterpreter: Codable, Sendable {
    /// The code to run.
    let code: String
    /// The unique ID of the code interpreter tool call.
    let id: String
    /// The results of the code interpreter tool call.
    let result: [OpenAIModelReponseContextCodeInterpreterResult]
    /// The status of the code interpreter tool call.
    let status: OpenAIModelReponseContextInputStatus
    let type: OpenAIModelReponseContextType = .code_interpreter_call
    /// The ID of the container used to run the code.
    let container_id: String

    enum CodingKeys: CodingKey {
        case code
        case id
        case result
        case status
        case type
        case container_id
    }
}

/// Execute a shell command on the server.
public struct OpenAIModelReponseContextLocalShellRequestAction: Codable, Sendable {
    /// The command to run.
    let command: [String]
    /// Environment variables to set for the command.
    let env: [String: String]
    let type: String = "exec"
    /// Optional timeout in milliseconds for the command.
    let timeout_ms: Int?
    /// Optional user to run the command as.
    let user: String?
    /// Optional working directory to run the command in.
    let working_directory: String?

    enum CodingKeys: CodingKey {
        case command
        case env
        case type
        case timeout_ms
        case user
        case working_directory
    }
}

/// A tool call to run a command on the local shell.
public struct OpenAIModelReponseContextLocalShellRequest: Codable, Sendable {
    let type: OpenAIModelReponseContextType = .local_shell_call
    let status: String
    /// The unique ID of the local shell call.
    let id: String
    /// The unique ID of the local shell tool call generated by the model.
    let call_id: String
    /// Execute a shell command on the server.
    let action: OpenAIModelReponseContextLocalShellRequestAction

    enum CodingKeys: CodingKey {
        case type
        case status
        case id
        case call_id
        case action
    }
}

/// The output of a local shell tool call.
public struct OpenAIModelReponseContextLocalShellResponse: Codable, Sendable {
    /// A JSON string of the output of the local shell tool call.
    let output: String
    let type: OpenAIModelReponseContextType = .local_shell_call_output
    /// The unique ID of the local shell tool call generated by the model.
    let id: String?
    let status: OpenAIModelReponseContextInputStatus?

    enum CodingKeys: CodingKey {
        case output
        case type
        case id
        case status
    }
}

public struct OpenAIModelReponseContextMcpListTool: Codable, Sendable {
    /// The JSON schema describing the tool's input.
    let input_schema: DynamicJSON.JSONSchema
    let name: String
    /// Additional annotations about the tool.
    let annotations: String? // TODO: determine the type
    /// The description of the tool.
    let description: String?
}

/// A list of tools available on an MCP server.
public struct OpenAIModelReponseContextMcpList: Codable, Sendable {
    /// The unique ID of the list.
    let id: String
    /// The label of the MCP server.
    let server_label: String
    /// The tools available on the server.
    let tools: [OpenAIModelReponseContextMcpListTool]
    let type: String
    /// Error message if the server could not list tools.
    let error: String?
}

/// A request for human approval of a tool invocation.
public struct OpenAIModelReponseContextMcpApprovalRequest: Codable, Sendable {
    /// A JSON string of arguments for the tool.
    let arguments: String
    /// The unique ID of the approval request.
    let id: String
    /// The name of the tool to run.
    let name: String
    /// The label of the MCP server making the request.
    let server_label: String
    let type: OpenAIModelReponseContextType = .mcp_approval_request

    enum CodingKeys: CodingKey {
        case arguments
        case id
        case name
        case server_label
        case type
    }
}

/// A response to an MCP approval request.
public struct OpenAIModelReponseContextMcpApprovalResponse: Codable, Sendable {
    /// The ID of the approval request being answered.
    let approval_request_id: String
    /// Whether the request was approved.
    let approve: Bool
    let type: OpenAIModelReponseContextType = .mcp_approval_response
    /// The unique ID of the approval response
    let id: String
    /// Optional reason for the decision.
    let reason: String?

    enum CodingKeys: CodingKey {
        case approval_request_id
        case approve
        case type
        case id
        case reason
    }
}

/// An invocation of a tool on an MCP server.
public struct OpenAIModelReponseContextMcpToolCall: Codable, Sendable {
    /// A JSON string of arguments for the tool.
    let arguments: String
    /// The unique ID of the approval request.
    let id: String
    /// The name of the tool to run.
    let name: String
    /// The label of the MCP server making the request.
    let server_label: String
    let type: OpenAIModelReponseContextType = .mcp_call
    /// The error from the tool call, if any.
    let error: String?
    /// The output from the tool call.
    let output: String?

    enum CodingKeys: CodingKey {
        case arguments
        case id
        case name
        case server_label
        case type
        case error
        case output
    }
}

public enum OpenAIModelReponseContextType: String, Codable, Sendable {
    case message
    case file_search_call
    case computer_call
    case computer_call_output
    case web_search_call
    case function_call
    case function_call_output
    case reasoning
    case image_generation_call
    case code_interpreter_call
    case local_shell_call
    case local_shell_call_output
    case mcp_list_tools
    case mcp_approval_request
    case mcp_approval_response
    case mcp_call
}

/// An item representing part of the context for the response to be generated by the model.
/// Can contain text, images, and audio inputs, as well as previous assistant responses and tool call outputs.
public enum OpenAIModelReponseContext: Codable, Sendable {
    case input(OpenAIModelReponseContextInput)
    case output(OpenAIModelReponseContextOutput)
    case fileSearchToolCall(OpenAIModelReponseContextFileSearchToolCall)
    case computerToolCallRequest(OpenAIModelReponseContextComputerToolCallRequest)
    case computerToolResponse(OpenAIModelReponseContextComputerToolCallReponse)
    case webSearchToolCall(OpenAIModelReponseContextWebSearchToolCall)
    case funcToolCall(OpenAIModelReponseContextFuncToolCall)
    case funcToolCallResponse(OpenAIModelReponseContextFuncToolCallOutput)
    case reasoning(OpenAIModelReponseContextReasoning)
    case imageGeneration(OpenAIModelReponseContextImageGeneration)
    case codeInterpreter(OpenAIModelReponseContextCodeInterpreter)
    case localShellRequest(OpenAIModelReponseContextLocalShellRequest)
    case localShellResponse(OpenAIModelReponseContextLocalShellResponse)
    case mcpToolList(OpenAIModelReponseContextMcpList)
    case mcpApprovalRequest(OpenAIModelReponseContextMcpApprovalRequest)
    case mcpApprovalResponse(OpenAIModelReponseContextMcpApprovalResponse)
    case mcpToolCall(OpenAIModelReponseContextMcpToolCall)

    public enum CodingKeys: String, CodingKey {
        case type
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .input(let input):
            try container.encode(input)
        case .output(let output):
            try container.encode(output)
        case .fileSearchToolCall(let fileSearchToolCall):
            try container.encode(fileSearchToolCall)
        case .computerToolCallRequest(let computerToolCallRequest):
            try container.encode(computerToolCallRequest)
        case .computerToolResponse(let computerToolResponse):
            try container.encode(computerToolResponse)
        case .webSearchToolCall(let webSearchToolCall):
            try container.encode(webSearchToolCall)
        case .funcToolCall(let funcToolCall):
            try container.encode(funcToolCall)
        case .funcToolCallResponse(let funcToolCallResponse):
            try container.encode(funcToolCallResponse)
        case .reasoning(let reasoning):
            try container.encode(reasoning)
        case .imageGeneration(let imageGeneration):
            try container.encode(imageGeneration)
        case .codeInterpreter(let codeInterpreter):
            try container.encode(codeInterpreter)
        case .localShellRequest(let localShellRequest):
            try container.encode(localShellRequest)
        case .localShellResponse(let localShellResponse):
            try container.encode(localShellResponse)
        case .mcpToolList(let mcpToolList):
            try container.encode(mcpToolList)
        case .mcpApprovalRequest(let mcpApprovalRequest):
            try container.encode(mcpApprovalRequest)
        case .mcpApprovalResponse(let mcpApprovalResponse):
            try container.encode(mcpApprovalResponse)
        case .mcpToolCall(let mcpToolCall):
            try container.encode(mcpToolCall)
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let type = try container.decode(OpenAIModelReponseContextType.self, forKey: .type)
        switch type {
        case .message:
            if let input = try? OpenAIModelReponseContextInput(from: decoder) {
                self = .input(input)
            } else if let output = try? OpenAIModelReponseContextOutput(from: decoder) {
                self = .output(output)
            } else {
                throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Cannot decode OpenAIModelReponseContext"))
            }
        case .file_search_call:
            self = try .fileSearchToolCall(.init(from: decoder))
        case .computer_call:
            self = try .computerToolCallRequest(.init(from: decoder))
        case .computer_call_output:
            self = try .computerToolResponse(.init(from: decoder))
        case .web_search_call:
            self = try .webSearchToolCall(.init(from: decoder))
        case .function_call:
            self = try .funcToolCall(.init(from: decoder))
        case .function_call_output:
            self = try .funcToolCallResponse(.init(from: decoder))
        case .reasoning:
            self = try .reasoning(.init(from: decoder))
        case .image_generation_call:
            self = try .imageGeneration(.init(from: decoder))
        case .code_interpreter_call:
            self = try .codeInterpreter(.init(from: decoder))
        case .local_shell_call:
            self = try .localShellRequest(.init(from: decoder))
        case .local_shell_call_output:
            self = try .localShellResponse(.init(from: decoder))
        case .mcp_list_tools:
            self = try .mcpToolList(.init(from: decoder))
        case .mcp_approval_request:
            self = try .mcpApprovalRequest(.init(from: decoder))
        case .mcp_approval_response:
            self = try .mcpApprovalResponse(.init(from: decoder))
        case .mcp_call:
            self = try .mcpToolCall(.init(from: decoder))
        }
    }
}

public enum ModelReponseRequestInputItemType: String, Codable, Sendable {
    case message
    case item
    case reference
}

public struct ModelReponseRequestInputItemReference: Codable, Sendable {
    let id: String
    let type: String = "item_reference"

    public enum CodingKeys: String, CodingKey {
        case id
        case type
    }
}

public enum OpenAIModelReponseRequestInputItem: Codable, Sendable {
    case message(OpenAIModelReponseRequestInputItemMessage)
    case output(OpenAIModelReponseContext)
    case reference(ModelReponseRequestInputItemReference)

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let modelReponseRequestInputItemMessage = try? container.decode(OpenAIModelReponseRequestInputItemMessage.self) {
            self = .message(modelReponseRequestInputItemMessage)
            return
        }

        if let modelReponseRequestInputItemContext = try? container.decode(OpenAIModelReponseContext.self) {
            self = .output(modelReponseRequestInputItemContext)
            return
        }

        if let modelReponseRequestInputItemReference = try? container.decode(ModelReponseRequestInputItemReference.self) {
            self = .reference(modelReponseRequestInputItemReference)
            return
        }

        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode ModelReponseRequestInputItem")
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .message(let modelReponseRequestInputItemMessage):
            try container.encode(modelReponseRequestInputItemMessage)
        case .output(let modelReponseRequestInputItemContext):
            try container.encode(modelReponseRequestInputItemContext)
        case .reference(let modelReponseRequestInputItemReference):
            try container.encode(modelReponseRequestInputItemReference)
        }
    }
}

public enum OpenAIModelReponseRequestInput: Codable, Sendable {
    case text(String)
    case items([OpenAIModelReponseRequestInputItem])

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .text(let string):
            try container.encode(string)
        case .items(let array):
            try container.encode(array)
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()

        // First try to decode as string
        if let stringValue = try? container.decode(String.self) {
            self = .text(stringValue)
            return
        }

        // Then try to decode as array of input items
        if let itemsArray = try? container.decode([OpenAIModelReponseRequestInputItem].self) {
            self = .items(itemsArray)
            return
        }

        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode ModelReponseRequestInput")
    }
}

public enum ModelReponseRequestAdditionalData: String, Codable, Sendable {
    /// Include the search results of the file search tool call.
    case fileSearchCallResults = "file_search_call.results"

    /// Include image urls from the input message.
    case inputMessageImageUrl = "message.input_image.image_url"

    ///  Include image urls from the computer call output.
    case computerCallOutputImageUrl = "computer_call_output.output.image_url"

    /// Includes an encrypted version of reasoning tokens in reasoning item outputs.
    /// This enables reasoning items to be used in multi-turn conversations when using the Responses API
    /// statelessly (like when the store parameter is set to false, or when an organization is enrolled in the zero data retention program).
    case reasoningEncryptedContent = "reasoning.encrypted_content"
}

public enum ModelReponseRequestResoningEffort: String, Codable, Sendable {
    case low
    case medium
    case high
}

public enum ModelReponseRequestResoningSummary: Codable, Sendable {
    case auto
    case concise
    case detailed
}

public struct OpenAIModelReponseRequestResoning: Codable, Sendable {
    /// Constrains effort on reasoning for reasoning models.
    /// Currently supported values are low, medium, and high.
    /// Reducing reasoning effort can result in faster responses and fewer tokens used on reasoning in a response.
    ///
    /// o-series models only
    /// Defaults to medium
    let effort: ModelReponseRequestResoningEffort?

    /// A summary of the reasoning performed by the model.
    /// This can be useful for debugging and understanding the model's reasoning process.
    ///
    /// computer-use-preview only
    let summary: ModelReponseRequestResoningSummary?

    enum CodingKeys: String, CodingKey {
        case effort
        case summary = "summary"
    }
}

public struct ModelReponseRequestTextConfigurationFormatText: Codable, Sendable {
    let type: ModelReponseRequestTextConfigurationFormatType = .text

    public enum CodingKeys: String, CodingKey {
        case type
    }
}

/// JSON Schema response format. Used to generate structured JSON responses.
/// Learn more about [Structured Outputs](https://platform.openai.com/docs/guides/structured-outputs).
public struct ModelReponseRequestTextConfigurationFormatJsonSchema: Codable, Sendable {
    let type: ModelReponseRequestTextConfigurationFormatType = .jsonSchema
    /// The name of the response format.
    /// Must be a-z, A-Z, 0-9, or contain underscores and dashes, with a maximum length of 64.
    let name: String

    /// A description of what the response format is for, used by the model to determine how to respond in the format.
    let description: String?

    /// Whether to enable strict schema adherence when generating the output.
    /// If set to true, the model will always follow the exact `schema` defined in the schema field.
    /// Only a subset of JSON Schema is supported when `strict` is `true`.
    /// To learn more, read the [Structured Outputs guide](https://platform.openai.com/docs/guides/structured-outputs).
    let strict: Bool?

    /// The schema for the response format, described as a JSON Schema object.
    /// Learn how to build JSON schemas [here](https://json-schema.org).
    let schema: JSONSchema

    public enum CodingKeys: String, CodingKey {
        case type
        case name
        case description
        case strict
        case schema
    }
}

/// JSON object response format.
/// An older method of generating JSON responses.
/// Using `json_schema` is recommended for models that support it.
/// Note that the model will not generate JSON without a system or user message instructing it to do so.
public struct ModelReponseRequestTextConfigurationFormatJson: Codable, Sendable {
    let type: ModelReponseRequestTextConfigurationFormatType = .json

    public enum CodingKeys: String, CodingKey {
        case type
    }
}

public enum ModelReponseRequestTextConfigurationFormatType: String, Codable, Sendable {
    case text = "text"
    case jsonSchema = "json_schema"
    case json = "json_object"
}

public enum ModelReponseRequestTextConfigurationFormat: Codable, Sendable {
    case text(ModelReponseRequestTextConfigurationFormatText)
    case jsonSchema(ModelReponseRequestTextConfigurationFormatJsonSchema)
    case json(ModelReponseRequestTextConfigurationFormatJson)

    public enum CodingKeys: String, CodingKey {
        case type
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .text(let text):
            try container.encode(text)
        case .jsonSchema(let jsonSchema):
            try container.encode(jsonSchema)
        case .json(let json):
            try container.encode(json)
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let type = try container.decode(ModelReponseRequestTextConfigurationFormatType.self, forKey: .type)
        switch type {
        case .text:
            self = try .text(ModelReponseRequestTextConfigurationFormatText(from: decoder))
        case .jsonSchema:
            self = try .jsonSchema(ModelReponseRequestTextConfigurationFormatJsonSchema(from: decoder))
        case .json:
            self = try .json(ModelReponseRequestTextConfigurationFormatJson(from: decoder))
        }
    }
}

public struct openAIModelReponseRequestTextConfiguration: Codable, Sendable {
    let format: ModelReponseRequestTextConfigurationFormat?
}

/// Controls which (if any) tool is called by the model.
public enum ModelReponseRequestToolChoiceToolChoiceMode: String, Codable, Sendable {
    case none
    case auto
    case required
}

public enum ModelReponseRequestToolChoiceHostedToolType: String, Codable, Sendable {
    case file_search
    case web_search_preview
    case computer_use_preiew
    case code_interpreter
    case mcp
    case image_generation
}

/// Indicates that the model should use a built-in tool to generate a response.
///
/// Learn more about [built-in tools](https://platform.openai.com/docs/guides/tools).
public struct ModelReponseRequestToolChoiceHostedTool: Codable, Sendable {
    let type: ModelReponseRequestToolChoiceHostedToolType
}

/// Use this option to force the model to call a specific function.
public struct ModelReponseRequestToolChoiceFunctionTool: Codable, Sendable {
    let name: String
    let type: String = "function"

    public enum CodingKeys: String, CodingKey {
        case name
        case type
    }
}

public enum OpenAIModelReponseRequestToolChoice: Codable, Sendable {
    case toolChoiceMode(ModelReponseRequestToolChoiceToolChoiceMode)
    case hostedTool(ModelReponseRequestToolChoiceHostedTool)
    case functionTool(ModelReponseRequestToolChoiceFunctionTool)

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .toolChoiceMode(let modelReponseRequestToolChoiceToolChoiceMode):
            try container.encode(modelReponseRequestToolChoiceToolChoiceMode)
        case .hostedTool(let modelReponseRequestToolChoiceHostedTool):
            try container.encode(modelReponseRequestToolChoiceHostedTool)
        case .functionTool(let modelReponseRequestToolChoiceFunctionTool):
            try container.encode(modelReponseRequestToolChoiceFunctionTool)
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Try to decode as simple string (for tool choice mode)
        if let mode = try? container.decode(ModelReponseRequestToolChoiceToolChoiceMode.self) {
            self = .toolChoiceMode(mode)
            return
        }

        // Try to decode as hosted tool
        if let hostedTool = try? container.decode(ModelReponseRequestToolChoiceHostedTool.self) {
            self = .hostedTool(hostedTool)
            return
        }

        // Try to decode as function tool
        if let functionTool = try? container.decode(ModelReponseRequestToolChoiceFunctionTool.self) {
            if functionTool.type == "function" {
                self = .functionTool(functionTool)
                return
            }
        }

        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode ModelReponseRequestToolChoice")
    }
}

public enum ModelReponseRequestToolFileSearchFilterComparisonType: Codable, Sendable {
    case eq
    case ne
    case gt
    case gte
    case lt
    case lte
}

public enum ModelReponseRequestToolFileSearchFilterComparisonValue: Codable, Sendable {
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .bool(let bool):
            try container.encode(bool)
        case .int(let int):
            try container.encode(int)
        case .double(let double):
            try container.encode(double)
        case .string(let string):
            try container.encode(string)
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Try decoding as each possible type
        if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
            return
        }

        // Try to decode as number (Int or Double)
        if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
            return
        }

        if let doubleValue = try? container.decode(Double.self) {
            self = .double(doubleValue)
            return
        }

        // Try to decode as string
        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
            return
        }

        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode ModelReponseRequestToolFileSearchFilterComparisonValue")
    }
}

public struct ModelReponseRequestToolFileSearchFilterComparison: Codable, Sendable {
    /// The key to compare against the value.
    let key: String
    let type: ModelReponseRequestToolFileSearchFilterComparisonType
    /// The value to compare against the attribute key;
    /// supports string, number, or boolean types.
    let value: ModelReponseRequestToolFileSearchFilterComparisonValue
}

public enum ModelReponseRequestToolFileSearchFilterCompoundType: String, Codable, Sendable {
    case and
    case or
}

/// Combine multiple filters using and or or.
public struct ModelReponseRequestToolFileSearchFilterCompound: Codable, Sendable {
    let filters: [ModelReponseRequestToolFileSearchFilter]
    let type: ModelReponseRequestToolFileSearchFilterCompoundType
}

public enum ModelReponseRequestToolFileSearchFilter: Codable, Sendable {
    case comparsion(ModelReponseRequestToolFileSearchFilterComparison)
    case compound(ModelReponseRequestToolFileSearchFilterCompound)

    public func encode(to encoder: any Encoder) throws {
        var conatiner = encoder.singleValueContainer()

        switch self {
        case .comparsion(let modelReponseRequestToolFileSearchFilterComparison):
            try conatiner.encode(modelReponseRequestToolFileSearchFilterComparison)
        case .compound(let modelReponseRequestToolFileSearchFilterCompound):
            try conatiner.encode(modelReponseRequestToolFileSearchFilterCompound)
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Try to decode as comparison
        if let comparison = try? container.decode(ModelReponseRequestToolFileSearchFilterComparison.self) {
            self = .comparsion(comparison)
            return
        }

        // Try to decode as compound
        if let compound = try? container.decode(ModelReponseRequestToolFileSearchFilterCompound.self) {
            self = .compound(compound)
            return
        }

        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode ModelReponseRequestToolFileSearchFilter")
    }
}

public struct ModelReponseRequestToolFileSearchRankingOption: Codable, Sendable {
    /// The ranker to use for the file search.
    let ranker: String?

    /// The score threshold for the file search, a number between 0 and 1.
    /// Numbers closer to 1 will attempt to return only the most relevant results, but may return fewer results.
    let scoreThreshold: Double?

    enum CodingKeys: String, CodingKey {
        case ranker
        case scoreThreshold = "score_threshold"
    }
}

/// A tool that searches for relevant content from uploaded files.
///
/// Learn more about the [file search tool](https://platform.openai.com/docs/guides/tools-file-search).
public struct OpenAIModelReponseRequestToolFileSearch: Codable, Sendable {
    let type: String = "file_search"

    /// The IDs of the vector stores to search.
    let vectorStoreIds: [String]

    /// A filter to apply based on file attributes.
    let filters: [ModelReponseRequestToolFileSearchFilter]?
    let maxNumResults: Int?

    /// Ranking options for search.
    let rankingOptions: ModelReponseRequestToolFileSearchRankingOption?

    public enum CodingKeys: String, CodingKey {
        case type
        case vectorStoreIds = "vector_store_ids"
        case filters
        case maxNumResults = "max_num_results"
        case rankingOptions = "ranking_options"
    }
}

/// Defines a function in your own code the model can choose to call.
///
/// Learn more about [function calling](https://platform.openai.com/docs/guides/function-calling).
public struct OpenAIModelReponseRequestToolFunction: Codable, Sendable {
    let type: String = "function"
    let name: String
    /// A JSON schema object describing the parameters of the function.
    let parameters: JSONSchema

    /// Whether to enforce strict parameter validation.
    /// Default true.
    let strict: Bool

    /// A description of the function.
    /// Used by the model to determine whether or not to call the function.
    let description: String?

    public enum CodingKeys: String, CodingKey {
        case type
        case name
        case parameters
        case strict
        case description
    }
}

/// A tool that controls a virtual computer.
///
/// Learn more about the [computer tool](https://platform.openai.com/docs/guides/tools-computer-use).
public struct OpenAIModelReponseRequestToolComputerUse: Codable, Sendable {
    let type: String = "computer_use_preview"

    /// The height of the computer display.
    let displayHeight: Int
    /// The width of the computer display.
    let displayWidth: Int
    /// The type of computer environment to control.
    let environment: String

    public enum CodingKeys: String, CodingKey {
        case type
        case displayHeight = "display_height"
        case displayWidth = "display_width"
        case environment
    }
}

public enum OpenAIModelReponseRequestToolWebSearchType: String, Codable, Sendable {
    case web_search_preview
    case web_search_preview_2025_03_11
}

public enum OpenAIModelReponseRequestToolWebSearchContextSize: String, Codable, Sendable {
    case low
    case medium
    case high
}

public struct OpenAIModelReponseRequestToolWebSearchUserLocation: Codable, Sendable {
    let type: String = "approximate"
    /// Free text input for the city of the user, e.g. San Francisco.
    let city: String
    /// The two-letter [ISO country code](https://en.wikipedia.org/wiki/ISO_3166-1) of the user, e.g. US.
    let country: String
    /// Free text input for the region of the user, e.g. California.
    let region: String
    /// The [IANA timezone](https://timeapi.io/documentation/iana-timezones) of the user, e.g. `America/Los_Angeles`.
    let timezone: String

    public enum CodingKeys: String, CodingKey {
        case type
        case city
        case country
        case region
        case timezone
    }
}

/// This tool searches the web for relevant results to use in a response.
///
/// Learn more about the [web search tool](https://platform.openai.com/docs/guides/tools-web-search).
public struct OpenAIModelReponseRequestToolWebSearch: Codable, Sendable {
    /// The type of the web search tool.
    let type: OpenAIModelReponseRequestToolWebSearchType
    /// High level guidance for the amount of context window space to use for the search.
    /// medium is the default.
    let searchContextSize: OpenAIModelReponseRequestToolWebSearchContextSize?

    /// Approximate location parameters for the search.
    let userLocation: OpenAIModelReponseRequestToolWebSearchUserLocation

    enum CodingKeys: String, CodingKey {
        case type
        case searchContextSize = "search_context_size"
        case userLocation = "user_location"
    }
}

public struct OpenAIModelReponseRequestToolMcpToolNames: Codable, Sendable {
    let tool_names: [String]
}

public enum OpenAIModelReponseRequestToolMcpAllowedTools: Codable, Sendable {
    case tools([String])
    case filter(OpenAIModelReponseRequestToolMcpToolNames)
}

public struct OpenAIModelReponseRequestToolMcpRequireApprovalFilter: Codable, Sendable {
    /// A list of tools that always require approval.
    let always: OpenAIModelReponseRequestToolMcpToolNames?
    /// A list of tools that never require approval.
    let never: OpenAIModelReponseRequestToolMcpToolNames?
    /// List of allowed tool names.
    let tool_names: [String]?
}

public enum OpenAIModelReponseRequestToolMcpRequireApprovalSetting: String, Codable, Sendable {
    case always
    case never
}

public enum OpenAIModelReponseRequestToolMcpRequireApproval: Codable, Sendable {
    case filter(OpenAIModelReponseRequestToolMcpRequireApprovalFilter)
    /// Specify a single approval policy for all tools. One of always or never.
    /// When set to `always`, all tools will require approval.
    /// When set to `never`, all tools will not require approval.
    case setting(OpenAIModelReponseRequestToolMcpRequireApprovalSetting)
}

/// Give the model access to additional tools via remote Model Context Protocol (MCP) servers.
/// [Learn more about MCP](https://platform.openai.com/docs/guides/tools-remote-mcp).
public struct OpenAIModelReponseRequestToolMcp: Codable, Sendable {
    /// A label for this MCP server, used to identify it in tool calls.
    let serverLabel: String
    /// The URL for the MCP server.
    let serverUrl: String
    let type: OpenAIModelReponseRequestToolType = .mcp
    /// List of allowed tool names or a filter object.
    let allowedTools: OpenAIModelReponseRequestToolMcpAllowedTools?
    /// Optional HTTP headers to send to the MCP server. Use for authentication or other purposes.
    let headers: [String: String]?
    /// Specify which of the MCP server's tools require approval.
    let requireApproval: OpenAIModelReponseRequestToolMcpRequireApproval?

    enum CodingKeys: String, CodingKey {
        case serverLabel = "server_label"
        case serverUrl = "server_url"
        case type
        case allowedTools = "allowed_tools"
        case headers
        case requireApproval = "require_approval"
    }
}

public struct OpenAIModelReponseRequestToolCodeInterpreterContainerConfiguration: Codable, Sendable {
    let type: String = "auto"
    /// An optional list of uploaded files to make available to your code.
    let fileIds: [String]?

    enum CodingKeys: String, CodingKey {
        case type
        case fileIds = "file_ids"
    }
}

public enum OpenAIModelReponseRequestToolCodeInterpreterContainer: Codable, Sendable {
    /// The container ID.
    case id(String)
    /// Configuration for a code interpreter container.
    /// Optionally specify the IDs of the files to run the code on.
    case configuration(OpenAIModelReponseRequestToolCodeInterpreterContainerConfiguration)
}

/// A tool that runs Python code to help generate a response to a prompt.
public struct OpenAIModelReponseRequestToolCodeInterpreter: Codable, Sendable {
    /// The code interpreter container.
    /// Can be a container ID or an object that specifies uploaded file IDs to make available to your code.
    let container: OpenAIModelReponseRequestToolCodeInterpreterContainer
    let type: OpenAIModelReponseRequestToolType = .code_interpreter

    enum CodingKeys: CodingKey {
        case container
        case type
    }
}

public enum OpenAIModelReponseRequestToolImageGenerationBackground: String, Codable, Sendable {
    case transparent, opaque, auto
}

public struct OpenAIModelReponseRequestToolImageGenerationImageMask: Codable, Sendable {
    /// File ID for the mask image.
    let file_id: String?
    /// Base64-encoded mask image.
    let image_url: String?
}

public enum OpenAIModelReponseRequestToolImageGenerationFormat: Codable, Sendable {
    case png, webp, jpeg
}

public enum OpenAIModelReponseRequestToolImageGenerationQuality: Codable, Sendable {
    case low, medium, high, auto
}

public enum OpenAIModelReponseRequestToolImageGenerationSize: String, Codable, Sendable {
    case s1024x1024 = "1024x1024"
    case s1024x1536 = "s1024x1536"
    case s1536x1024 = "s1536x1024"
    case auto
}

/// A tool that generates images using a model like gpt-image-1.
public struct OpenAIModelReponseRequestToolImageGeneration: Codable, Sendable {
    let type: OpenAIModelReponseRequestToolType = .image_generation
    /// Background type for the generated image.
    /// Default: auto.
    let background: OpenAIModelReponseRequestToolImageGenerationBackground?
    /// Optional mask for inpainting.
    let inputImageMask: OpenAIModelReponseRequestToolImageGenerationImageMask?
    /// The image generation model to use. Default: `gpt-image-1`.
    let model: String?
    /// Moderation level for the generated image. Default: auto
    let moderation: String?
    /// Compression level for the output image. Default: 100.
    let outputCompression: Int?
    /// The output format of the generated image. One of png, webp, or jpeg. Default: png.
    let outputFormat: OpenAIModelReponseRequestToolImageGenerationFormat?
    /// Number of partial images to generate in streaming mode, from 0 (default value) to 3.
    let partialImages: Int?
    /// The quality of the generated image. One of low, medium, high, or auto. Default: auto.
    let quality: OpenAIModelReponseRequestToolImageGenerationQuality?
    /// The size of the generated image. One of 1024x1024, 1024x1536, 1536x1024, or auto. Default: auto.
    let size: OpenAIModelReponseRequestToolImageGenerationSize?

    enum CodingKeys: String, CodingKey {
        case type
        case background
        case inputImageMask = "input_image_mask"
        case model
        case moderation
        case outputCompression = "output_compression"
        case outputFormat = "output_format"
        case partialImages = "partial_images"
        case quality
        case size
    }
}

/// A tool that allows the model to execute shell commands in a local environment.
public struct OpenAIModelReponseRequestToolLocalShell: Codable, Sendable {
    let type: OpenAIModelReponseRequestToolType = .local_shell

    enum CodingKeys: CodingKey {
        case type
    }
}

public enum OpenAIModelReponseRequestToolType: String, Codable, Sendable {
    case file_search
    case function
    case computer_use_preview
    case web_search_preview
    case web_search_preview_2025_03_11
    case mcp
    case code_interpreter
    case image_generation
    case local_shell
}

public enum OpenAIModelReponseRequestTool: Codable, Sendable {
    case function(OpenAIModelReponseRequestToolFunction)
    case fileSearch(OpenAIModelReponseRequestToolFileSearch)
    case webSearch(OpenAIModelReponseRequestToolWebSearch)
    case computerUse(OpenAIModelReponseRequestToolComputerUse)
    case mcp(OpenAIModelReponseRequestToolMcp)
    case codeInterpreter(OpenAIModelReponseRequestToolCodeInterpreter)
    case imageGeneration(OpenAIModelReponseRequestToolImageGeneration)
    case localShell(OpenAIModelReponseRequestToolLocalShell)

    public enum CodingKeys: String, CodingKey {
        case type
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .fileSearch(let modelReponseRequestToolFileSearch):
            try container.encode(modelReponseRequestToolFileSearch)
        case .function(let modelReponseRequestToolFunction):
            try container.encode(modelReponseRequestToolFunction)
        case .computerUse(let modelReponseRequestToolComputerUse):
            try container.encode(modelReponseRequestToolComputerUse)
        case .webSearch(let modelReponseRequestToolWebSearch):
            try container.encode(modelReponseRequestToolWebSearch)
        case .mcp(let v):
            try container.encode(v)
        case .codeInterpreter(let v):
            try container.encode(v)
        case .imageGeneration(let v):
            try container.encode(v)
        case .localShell(let v):
            try container.encode(v)
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let type = try container.decode(OpenAIModelReponseRequestToolType.self, forKey: .type)
        switch type {
        case .file_search:
            self = try .fileSearch(.init(from: decoder))
        case .function:
            self = try .function(.init(from: decoder))
        case .computer_use_preview:
            self = try .computerUse(.init(from: decoder))
        case .web_search_preview:
            self = try .webSearch(.init(from: decoder))
        case .web_search_preview_2025_03_11:
            self = try .webSearch(.init(from: decoder))
        case .mcp:
            self = try .mcp(.init(from: decoder))
        case .code_interpreter:
            self = try .codeInterpreter(.init(from: decoder))
        case .image_generation:
            self = try .imageGeneration(.init(from: decoder))
        case .local_shell:
            self = try .localShell(.init(from: decoder))
        }
    }
}

public enum OpenAIModelReponseRequestTruncation: String, Codable, Sendable {
    /// If the context of this response and previous ones exceeds the model's context window size,
    /// the model will truncate the response to fit the context window by dropping input items in the middle of the conversation.
    case auto
    /// If a model response will exceed the context window size for a model, the request will fail with a 400 error.
    case disabled
}

public struct OpenAIModelReponseRequest: Codable, Sendable {
    /// Text, image, or file inputs to the model, used to generate a response.
    let input: OpenAIModelReponseRequestInput

    /// Model ID used to generate the response, like gpt-4o or o1.
    /// OpenAI offers a wide range of models with different capabilities, performance characteristics, and price points.
    /// Refer to the [model](https://platform.openai.com/docs/models) guide to browse and compare available models.
    let model: String

    /// Whether to run the model response in the background.
    /// [Learn more](https://platform.openai.com/docs/guides/background).
    ///
    /// Defaults to false
    let background: Bool?

    /// Specify additional output data to include in the model response.
    let include: [ModelReponseRequestAdditionalData]?

    /// Inserts a system (or developer) message as the first item in the model's context.
    ///
    /// When using along with `previous_response_id`,
    /// the instructions from a previous response will not be carried over to the next response.
    /// This makes it simple to swap out system (or developer) messages in new responses.
    let instructions: String?

    /// An upper bound for the number of tokens that can be generated for a response,
    /// including visible output tokens and [reasoning tokens](https://platform.openai.com/docs/guides/reasoning).
    let maxOutputTokens: Int?

    /// Set of 16 key-value pairs that can be attached to an object.
    /// This can be useful for storing additional information about the object in a structured format,
    /// and querying for objects via API or the dashboard.
    ///
    /// Keys are strings with a maximum length of 64 characters. Values are strings with a maximum length of 512 characters.
    let metadata: [String: String]?

    /// Whether to allow the model to run tool calls in parallel.
    /// Defaults to true.
    let parallelToolCalls: Bool?

    /// The unique ID of the previous response to the model.
    /// Use this to create multi-turn conversations.
    /// Learn more about [conversation state](https://platform.openai.com/docs/guides/conversation-state).
    let previousResponseId: String?

    /// Configuration options for [reasoning models](https://platform.openai.com/docs/guides/reasoning).
    ///
    /// o-series models only
    let reasoning: OpenAIModelReponseRequestResoning?

    /// Whether to store the generated model response for later retrieval via API.
    ///
    /// Defaults to true
    let store: Bool?

    /// If set to true, the model response data will be streamed
    /// to the client as it is generated using [server-sent events](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events#Event_stream_format).
    /// See the [Streaming section](https://platform.openai.com/docs/api-reference/responses-streaming) below for more information.
    ///
    /// Defaults to false
    let stream: Bool?

    /// What sampling temperature to use, between 0 and 2.
    /// Higher values like 0.8 will make the output more random,
    /// while lower values like 0.2 will make it more focused and deterministic.
    /// We generally recommend altering this or `top_p` but not both.
    ///
    /// Defaults to 1
    let temperature: Double?

    /// Configuration options for a text response from the model.
    /// Can be plain text or structured JSON data.
    ///
    /// Learn more:
    /// [Text inputs and outputs](https://platform.openai.com/docs/guides/text)
    /// [Structured Outputs](https://platform.openai.com/docs/guides/structured-outputs)
    let text: openAIModelReponseRequestTextConfiguration?

    /// How the model should select which tool (or tools) to use when generating a response.
    /// See the tools parameter to see how to specify which tools the model can call.
    let toolChoice: OpenAIModelReponseRequestToolChoice?

    /// An array of tools the model may call while generating a response.
    /// You can specify which tool to use by setting the `tool_choice` parameter.
    ///
    /// The two categories of tools you can provide the model are:
    ///   - Built-in tools: Tools that are provided by OpenAI that extend the model's capabilities,
    ///     like [web search](https://platform.openai.com/docs/guides/tools-web-search) or [file search](https://platform.openai.com/docs/guides/tools-file-search).
    ///     Learn more about [built-in](https://platform.openai.com/docs/guides/tools) tools.
    ///   - Function calls (custom tools): Functions that are defined by you,
    ///     enabling the model to call your own code.
    ///     Learn more about [function calling](https://platform.openai.com/docs/guides/function-calling).
    let tools: [OpenAIModelReponseRequestTool]?

    /// An alternative to sampling with temperature, called nucleus sampling,
    /// where the model considers the results of the tokens with `top_p` probability mass.
    /// So 0.1 means only the tokens comprising the top 10% probability mass are considered.
    /// We generally recommend altering this or `temperature` but not both.
    let topP: Double?

    /// The truncation strategy to use for the model response.
    /// Defaults to disabled
    let truncation: OpenAIModelReponseRequestTruncation?

    /// A unique identifier representing your end-user, which can help OpenAI to monitor and detect abuse.
    /// [Learn more](https://platform.openai.com/docs/guides/safety-best-practices#end-user-ids).
    let user: String?

    enum CodingKeys: String, CodingKey {
        case input
        case model
        case background
        case include
        case instructions
        case maxOutputTokens = "max_output_tokens"
        case metadata
        case parallelToolCalls = "parallel_tool_calls"
        case previousResponseId = "previous_response_id"
        case reasoning
        case store
        case stream
        case temperature
        case text
        case toolChoice
        case tools
        case topP = "top_p"
        case truncation
        case user
    }
}
