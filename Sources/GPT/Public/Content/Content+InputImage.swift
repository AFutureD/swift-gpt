//
//  Content+InputImage.swift
//  swift-gpt
//
//  Created by Huanan on 2025/10/30.
//

extension ContentType {
    static let inputImage = ContentType(rawValue: "Image")
}


public enum ImageInputDetailLevel: Sendable, Codable, Hashable {
    case auto
    case high
    case mid
    case low
}


public struct ImageInputContent: Sendable, Codable, Hashable {
    public let type: ContentType = .inputImage

    /// The role of the entity providing the content.
    public let role: ModelContentRole
    
    public let externalID: String?
    
    public let url: String?
    
    public let base64: String?

    public let detail: ImageInputDetailLevel?
    
    enum CodingKeys: String, CodingKey {
        case type
        case role
        case externalID = "external_id"
        case url
        case base64
        case detail
    }
    
    public init(role: ModelContentRole, externalID: String?, url: String?, base64: String?, detail: ImageInputDetailLevel?) {
        self.role = role
        self.externalID = externalID
        self.url = url
        self.base64 = base64
        self.detail = detail
    }
}
