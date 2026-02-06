import Foundation

/// Represents YAML frontmatter metadata from markdown files
public struct FrontMatter: Codable, Sendable {
    public let title: String?
    public let description: String?
    public let date: Date?
    public let tags: [String]?
    public let layout: String?

    /// Custom key-value pairs for extensibility
    public var additionalProperties: [String: String]?

    enum CodingKeys: String, CodingKey {
        case title
        case description
        case date
        case tags
        case layout
    }

    /// Default frontmatter with no metadata
    public static var `default`: FrontMatter {
        FrontMatter(
            title: nil,
            description: nil,
            date: nil,
            tags: nil,
            layout: nil,
            additionalProperties: nil
        )
    }

    public init(
        title: String? = nil,
        description: String? = nil,
        date: Date? = nil,
        tags: [String]? = nil,
        layout: String? = nil,
        additionalProperties: [String: String]? = nil
    ) {
        self.title = title
        self.description = description
        self.date = date
        self.tags = tags
        self.layout = layout
        self.additionalProperties = additionalProperties
    }
}
