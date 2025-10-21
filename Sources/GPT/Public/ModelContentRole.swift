
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

public extension ModelContentRole {
    /// The system role, providing high-level instructions.
    static let system = ModelContentRole(rawValue: "system")
    /// The assistant role, representing the LLM's responses.
    static let assistant = ModelContentRole(rawValue: "assistant")
    /// The user role, representing the end-user's input.
    static let user = ModelContentRole(rawValue: "user")
    /// The developer role, for developer-specific instructions.
    static let developer = ModelContentRole(rawValue: "developer")
}
