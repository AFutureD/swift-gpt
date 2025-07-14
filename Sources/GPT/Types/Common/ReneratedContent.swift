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
