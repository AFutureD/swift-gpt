
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
