import Foundation

/// Configuration options for markdown processing
public struct MarkdownOptions: Sendable {
    /// When true, disables GitHub-flavored markdown extensions (tables, strikethrough, task lists)
    /// and processes only CommonMark-compliant markdown
    public var strictMode: Bool

    /// When true, processes Hugo-style shortcodes in the content
    public var enableShortcodes: Bool

    /// When true, applies syntax highlighting to code blocks with language hints
    public var syntaxHighlighting: Bool

    /// When true, enables footnote support [^1]
    public var enableFootnotes: Bool

    /// Default options with all features enabled
    public static var `default`: MarkdownOptions {
        MarkdownOptions(
            strictMode: false,
            enableShortcodes: true,
            syntaxHighlighting: true,
            enableFootnotes: true
        )
    }

    /// Strict CommonMark-only options
    public static var strict: MarkdownOptions {
        MarkdownOptions(
            strictMode: true,
            enableShortcodes: false,
            syntaxHighlighting: true,
            enableFootnotes: false
        )
    }

    public init(
        strictMode: Bool = false,
        enableShortcodes: Bool = true,
        syntaxHighlighting: Bool = true,
        enableFootnotes: Bool = true
    ) {
        self.strictMode = strictMode
        self.enableShortcodes = enableShortcodes
        self.syntaxHighlighting = syntaxHighlighting
        self.enableFootnotes = enableFootnotes
    }
}
