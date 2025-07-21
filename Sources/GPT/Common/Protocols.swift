// MARK: Model Generation

public struct GeneratedContentType: RawRepresentable, Codable, Hashable, Sendable {

    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension GeneratedContentType: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}

public protocol GeneratedItem: Sendable {
    associatedtype Content

    var type: GeneratedContentType { get }
    var content: Content? { get }
}

public protocol GeneratedSortable: Sendable {
    var index: Int? { get }
}

public typealias GeneratedSortableItem = GeneratedSortable & GeneratedItem

public protocol PartialUpdatable: Sendable {
    associatedtype Delta

    var delta: Delta { get }
}

public typealias PartialUpdatableItem = PartialUpdatable & GeneratedItem

// MARK: Model Inputs

public struct ModelInputContentRole: RawRepresentable, Hashable, Codable, Sendable {
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension ModelInputContentRole: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}

extension ModelInputContentRole {
    public static let system = ModelInputContentRole(rawValue: "system")
    public static let assistant = ModelInputContentRole(rawValue: "assistant")
    public static let user = ModelInputContentRole(rawValue: "user")
    public static let developer = ModelInputContentRole(rawValue: "developer")
}

public struct ModelInputContentType: RawRepresentable, Codable, Sendable {
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension ModelInputContentType: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}

public protocol ModelInputContent: Sendable {
    associatedtype Content: Encodable

    var type: ModelInputContentType { get }
    var role: ModelInputContentRole { get }

    var content: Content { get }
}
