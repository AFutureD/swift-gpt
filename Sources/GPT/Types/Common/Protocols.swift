// MARK: Model Generation

struct GeneratedContentType: RawRepresentable {
    let rawValue: String
}

protocol GeneratedItem: Identifiable, Sendable {
    associatedtype Content

    var type: GeneratedContentType { get }
    var content: Content? { get }
}

protocol PartialUpdatableItem: GeneratedItem {
    associatedtype Delta

    var delta: Delta { get }
}

// MARK: Model Inputs

struct ModelInputContentRole: RawRepresentable, Hashable, Sendable {
    let rawValue: String
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

protocol ModelInputContent: Sendable {
    associatedtype Content: Encodable
    
    var type: ModelInputContentType { get }
    var role: ModelInputContentRole { get }
    
    var content: Content { get }
}
