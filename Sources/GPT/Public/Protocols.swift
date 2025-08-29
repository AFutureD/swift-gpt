// MARK: Model Generation

public typealias GeneratedContentType = ContentType
public typealias ModelInputContentType = ContentType

/// A type that represents the content type of a generated item from an LLM.
public struct ContentType: RawRepresentable, Codable, Hashable, Sendable {

    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension ContentType: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}

// MARK: Model Inputs

/// A type that represents the role of the entity providing input to an LLM (e.g., user, assistant).
public struct ModelContentRole: RawRepresentable, Hashable, Codable, Sendable {
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension ModelContentRole: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}

extension ModelContentRole {
    /// The system role, providing high-level instructions.
    public static let system = ModelContentRole(rawValue: "system")
    /// The assistant role, representing the LLM's responses.
    public static let assistant = ModelContentRole(rawValue: "assistant")
    /// The user role, representing the end-user's input.
    public static let user = ModelContentRole(rawValue: "user")
    /// The developer role, for developer-specific instructions.
    public static let developer = ModelContentRole(rawValue: "developer")
}

// /// A type that represents the content type of an input to an LLM.
// public struct ModelInputContentType: RawRepresentable, Codable, Hashable, Sendable {
//     public let rawValue: String
    
//     public init(rawValue: String) {
//         self.rawValue = rawValue
//     }
// }

// extension ModelInputContentType: CustomStringConvertible {
//     public var description: String {
//         rawValue
//     }
// }

/// A protocol for content provided as input to an LLM.
public protocol ModelInputContent: Sendable {
    associatedtype Content: Encodable

    /// The type of the input content.
    var type: ModelInputContentType { get }
    /// The role of the entity providing the content.
    var role: ModelContentRole { get }

    /// The content itself.
    var content: Content { get }
}
