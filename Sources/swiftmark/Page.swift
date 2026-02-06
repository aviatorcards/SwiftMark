import Foundation

/// Represents a single markdown page with its metadata and content
public struct Page: Sendable {
    /// Relative path/identifier
    public let path: String

    /// Metadata extracted from YAML frontmatter
    public let frontMatter: FrontMatter

    /// Rendered HTML content from markdown
    public let content: String

    /// Original markdown source
    public let rawMarkdown: String

    /// File modification date
    public let modifiedDate: Date

    public init(
        path: String, frontMatter: FrontMatter, content: String, rawMarkdown: String,
        modifiedDate: Date
    ) {
        self.path = path
        self.frontMatter = frontMatter
        self.content = content
        self.rawMarkdown = rawMarkdown
        self.modifiedDate = modifiedDate
    }

    /// Display title (from frontmatter or derived from filename)
    public var displayTitle: String {
        if let title = frontMatter.title {
            return title
        }
        // Derive from filename
        let filename = (path as NSString).lastPathComponent
        return filename.replacingOccurrences(of: ".md", with: "")
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
}
