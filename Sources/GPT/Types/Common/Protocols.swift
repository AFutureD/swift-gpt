// MARK: Model Generation

struct GeneratedContentType: RawRepresentable {
    let rawValue: String
}

extension GeneratedContentType: CustomStringConvertible {
    var description: String {
        rawValue
    }
}

protocol GeneratedItem: Sendable {
    associatedtype Content

    var type: GeneratedContentType { get }
    var content: Content? { get }
}

protocol GeneratedSortable: Sendable {
    var index: Int? { get }
}

typealias GeneratedSortableItem = GeneratedSortable & GeneratedItem

protocol PartialUpdatable: Sendable {
    associatedtype Delta

    var delta: Delta { get }
}

typealias PartialUpdatableItem = PartialUpdatable & GeneratedItem

// MARK: Model Inputs

struct ModelInputContentRole: RawRepresentable, Hashable, Sendable {
    let rawValue: String
}

extension ModelInputContentRole: CustomStringConvertible {
    var description: String {
        rawValue
    }
}

extension ModelInputContentRole {
    static let system = ModelInputContentRole(rawValue: "system")
    static let assistant = ModelInputContentRole(rawValue: "assistant")
    static let user = ModelInputContentRole(rawValue: "user")
    static let developer = ModelInputContentRole(rawValue: "developer")
}

struct ModelInputContentType: RawRepresentable, Sendable {
    let rawValue: String
}

extension ModelInputContentType: CustomStringConvertible {
    var description: String {
        rawValue
    }
}

protocol ModelInputContent: Sendable {
    associatedtype Content: Encodable

    var type: ModelInputContentType { get }
    var role: ModelInputContentRole { get }

    var content: Content { get }
}
