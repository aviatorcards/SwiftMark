import Foundation
import Markdown
import Yams

/// Errors that can occur during markdown processing
public enum SwiftMarkError: Error, Sendable {
    case fileReadError(URL, underlying: Error)
    case invalidFrontMatter(String)
    case shortcodeError(name: String, message: String)
    case processingError(String)
}

/// Processes markdown files into Page objects
public final class MarkdownProcessor: Sendable {
    private let shortcodeProcessor = ShortcodeProcessor()
    private let options: MarkdownOptions

    public init(options: MarkdownOptions = .default) {
        self.options = options
    }

    /// Process a markdown file into a Page
    public func process(file: URL, relativeTo baseURL: URL) throws -> Page {
        // Read file content
        let fileContent: String
        do {
            fileContent = try String(contentsOf: file, encoding: .utf8)
        } catch {
            throw SwiftMarkError.fileReadError(file, underlying: error)
        }

        // Process content
        let (frontMatter, processedHTML) = process(content: fileContent)

        // Calculate relative path
        let relativePath = file.path.replacingOccurrences(
            of: baseURL.path + "/",
            with: ""
        )

        // Get file metadata
        let attributes: [FileAttributeKey: Any]
        do {
            attributes = try FileManager.default.attributesOfItem(atPath: file.path)
        } catch {
            throw SwiftMarkError.fileReadError(file, underlying: error)
        }
        
        let modifiedDate = attributes[.modificationDate] as? Date ?? Date()

        // Re-extract raw markdown for the Page object
        let (_, markdown): (FrontMatter?, String)
        do {
            (_, markdown) = try extractFrontMatter(from: fileContent)
        } catch {
            throw SwiftMarkError.invalidFrontMatter(error.localizedDescription)
        }

        return Page(
            path: relativePath,
            frontMatter: frontMatter ?? .default,
            content: processedHTML,
            rawMarkdown: markdown,
            modifiedDate: modifiedDate
        )
    }

    /// Process raw markdown content string
    /// Returns the parsed frontmatter and rendered HTML
    public func process(content: String) -> (frontMatter: FrontMatter?, html: String) {
        // Extract frontmatter if present
        let (frontMatter, markdown) = (try? extractFrontMatter(from: content)) ?? (nil, content)

        // Parse markdown to HTML
        let htmlContent = renderHTML(from: markdown)

        // Process shortcodes in the HTML (after markdown rendering) if enabled
        let processedHTML = options.enableShortcodes
            ? shortcodeProcessor.process(htmlContent)
            : htmlContent

        return (frontMatter, processedHTML)
    }

    /// Process raw markdown content to attributed string for rich text display
    /// Returns the parsed frontmatter and rendered attributed string
    public func processToAttributedString(content: String) -> (
        frontMatter: FrontMatter?, attributedString: NSAttributedString
    ) {
        // Extract frontmatter if present
        let (frontMatter, markdown) = (try? extractFrontMatter(from: content)) ?? (nil, content)

        // Render to attributed string
        let renderer = AttributedStringRenderer()
        let attributedString = renderer.render(markdown, options: options)

        return (frontMatter, attributedString)
    }

    /// Parse raw markdown content string to AST
    /// Returns the parsed frontmatter and Document AST
    public func parse(_ content: String) -> (frontMatter: FrontMatter?, document: Document) {
        let (frontMatter, markdown) = (try? extractFrontMatter(from: content)) ?? (nil, content)
        let document = Document(parsing: markdown)
        return (frontMatter, document)
    }

    /// Process multiple markdown files into Page objects asynchronously
    public func process(files: [URL], relativeTo baseURL: URL) async throws -> [Page] {
        return try await withThrowingTaskGroup(of: Page.self) { group in
            for file in files {
                group.addTask {
                    try self.process(file: file, relativeTo: baseURL)
                }
            }

            var pages: [Page] = []
            for try await page in group {
                pages.append(page)
            }
            return pages
        }
    }

    /// Extract YAML frontmatter from markdown content
    private func extractFrontMatter(from content: String) throws -> (FrontMatter?, String) {
        // Check for YAML frontmatter delimited by ---
        let lines = content.components(separatedBy: .newlines)

        guard lines.first == "---" else {
            return (nil, content)
        }

        // Find closing ---
        guard let endIndex = lines.dropFirst().firstIndex(of: "---") else {
            return (nil, content)
        }

        // Extract YAML content
        let yamlLines = lines[1..<endIndex]
        let yamlString = yamlLines.joined(separator: "\n")

        // Parse YAML
        let decoder = YAMLDecoder()
        let frontMatter = try? decoder.decode(FrontMatter.self, from: yamlString)

        // Get remaining markdown content
        let markdownLines = lines[(endIndex + 1)...]
        let markdown = markdownLines.joined(separator: "\n")

        return (frontMatter, markdown)
    }

    /// Render markdown to HTML using swift-markdown
    private func renderHTML(from markdown: String) -> String {
        let document = Document(parsing: markdown)
        var renderer = MarkdownHTMLRenderer(
            strictMode: options.strictMode,
            syntaxHighlighting: options.syntaxHighlighting,
            enableFootnotes: options.enableFootnotes
        )
        return renderer.render(document)
    }
}

/// HTML renderer for markdown documents
private struct MarkdownHTMLRenderer: MarkupWalker {
    private var html = ""
    private var footnotes: [String: String] = [:]
    private var footnoteOrder: [String] = []
    private let highlighter = SyntaxHighlighter()
    private let strictMode: Bool
    private let syntaxHighlighting: Bool
    private let enableFootnotes: Bool

    init(strictMode: Bool = false, syntaxHighlighting: Bool = true, enableFootnotes: Bool = true) {
        self.strictMode = strictMode
        self.syntaxHighlighting = syntaxHighlighting
        self.enableFootnotes = enableFootnotes
    }

    mutating func render(_ document: Document) -> String {
        html = ""
        footnotes = [:]
        footnoteOrder = []
        visit(document)
        
        // Append footnotes at the end if any were found
        if !footnoteOrder.isEmpty && enableFootnotes {
            html += "\n<div class=\"footnotes\">\n<hr />\n<ol>\n"
            for label in footnoteOrder {
                if let content = footnotes[label] {
                    html += "<li id=\"fn:\(label.htmlEscaped)\">"
                    html += content
                    html += " <a href=\"#fnref:\(label.htmlEscaped)\" class=\"footnote-backref\">↩</a>"
                    html += "</li>\n"
                }
            }
            html += "</ol>\n</div>\n"
        }
        
        return html
    }

    mutating func visitHeading(_ heading: Heading) {
        let tag = "h\(heading.level)"
        html += "<\(tag)>"
        descendInto(heading)
        html += "</\(tag)>\n"
    }

    mutating func visitParagraph(_ paragraph: Paragraph) {
        html += "<p>"
        descendInto(paragraph)
        html += "</p>\n"
    }

    mutating func visitText(_ text: Text) {
        html += text.string.htmlEscaped
    }

    mutating func visitStrong(_ strong: Strong) {
        html += "<strong>"
        descendInto(strong)
        html += "</strong>"
    }

    mutating func visitEmphasis(_ emphasis: Emphasis) {
        html += "<em>"
        descendInto(emphasis)
        html += "</em>"
    }

    mutating func visitCodeBlock(_ codeBlock: CodeBlock) {
        let language = codeBlock.language ?? ""
        let code = codeBlock.code

        if !language.isEmpty && syntaxHighlighting {
            // Use syntax highlighter for known languages
            html += highlighter.highlight(code: code, language: language)
            html += "\n"
        } else if !language.isEmpty {
            // Language specified but highlighting disabled
            html += "<pre><code class=\"language-\(language.htmlEscaped)\">"
            html += code.htmlEscaped
            html += "</code></pre>\n"
        } else {
            // No language specified, render as plain code
            html += "<pre><code>"
            html += code.htmlEscaped
            html += "</code></pre>\n"
        }
    }

    mutating func visitInlineCode(_ inlineCode: InlineCode) {
        html += "<code>\(inlineCode.code.htmlEscaped)</code>"
    }

    mutating func visitLink(_ link: Link) {
        let destination = link.destination ?? ""
        html += "<a href=\"\(destination.htmlEscaped)\">"
        descendInto(link)
        html += "</a>"
    }

    mutating func visitUnorderedList(_ unorderedList: UnorderedList) {
        html += "<ul>\n"
        descendInto(unorderedList)
        html += "</ul>\n"
    }

    mutating func visitOrderedList(_ orderedList: OrderedList) {
        html += "<ol>\n"
        descendInto(orderedList)
        html += "</ol>\n"
    }

    mutating func visitListItem(_ listItem: ListItem) {
        // In strict mode, ignore task list checkboxes (not CommonMark)
        if !strictMode, let checkbox = listItem.checkbox {
            let checked = checkbox == .checked ? " checked disabled" : " disabled"
            html += "<li><input type=\"checkbox\"\(checked) /> "
            descendInto(listItem)
            html += "</li>\n"
        } else {
            html += "<li>"
            descendInto(listItem)
            html += "</li>\n"
        }
    }

    mutating func visitBlockQuote(_ blockQuote: BlockQuote) {
        html += "<blockquote>\n"
        descendInto(blockQuote)
        html += "</blockquote>\n"
    }

    mutating func visitLineBreak(_ lineBreak: LineBreak) {
        html += "<br>\n"
    }

    mutating func visitSoftBreak(_ softBreak: SoftBreak) {
        html += " "
    }

    mutating func visitImage(_ image: Image) {
        let src = (image.source ?? "").htmlEscaped
        let alt = image.plainText.htmlEscaped
        let title = image.title.map { " title=\"\($0.htmlEscaped)\"" } ?? ""
        html += "<img src=\"\(src)\" alt=\"\(alt)\"\(title) />"
    }

    mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) {
        html += "<hr />\n"
    }

    mutating func visitHTMLBlock(_ htmlBlock: HTMLBlock) {
        // Pass through raw HTML blocks as-is (user-provided HTML)
        html += htmlBlock.rawHTML
        html += "\n"
    }

    mutating func visitStrikethrough(_ strikethrough: Strikethrough) {
        // In strict mode, strikethrough is not CommonMark - render as plain text
        if strictMode {
            descendInto(strikethrough)
        } else {
            html += "<del>"
            descendInto(strikethrough)
            html += "</del>"
        }
    }

    // MARK: - Table Support

    mutating func visitTable(_ table: Table) {
        // In strict mode, tables are not CommonMark - render as plain text
        if strictMode {
            descendInto(table)
            html += "\n"
        } else {
            html += "<table>\n"
            descendInto(table)
            html += "</table>\n"
        }
    }

    mutating func visitTableHead(_ head: Table.Head) {
        if strictMode {
            // In strict mode, render cells as plain text separated by pipes
            for cell in head.cells {
                for child in cell.children {
                    visit(child)
                }
                html += " | "
            }
            html += "\n"
        } else {
            html += "<thead>\n<tr>\n"
            let table = head.parent as? Table
            for (columnIndex, cell) in head.cells.enumerated() {
                let alignment = alignmentStyle(for: columnIndex, in: table)
                html += "<th\(alignment)>"
                for child in cell.children {
                    visit(child)
                }
                html += "</th>\n"
            }
            html += "</tr>\n</thead>\n"
        }
    }

    mutating func visitTableBody(_ body: Table.Body) {
        if strictMode {
            descendInto(body)
        } else {
            html += "<tbody>\n"
            descendInto(body)
            html += "</tbody>\n"
        }
    }

    mutating func visitTableRow(_ row: Table.Row) {
        if strictMode {
            // In strict mode, render cells as plain text separated by pipes
            for cell in row.cells {
                for child in cell.children {
                    visit(child)
                }
                html += " | "
            }
            html += "\n"
        } else {
            html += "<tr>\n"
            let table = row.parent?.parent as? Table
            for (columnIndex, cell) in row.cells.enumerated() {
                let alignment = alignmentStyle(for: columnIndex, in: table)
                html += "<td\(alignment)>"
                for child in cell.children {
                    visit(child)
                }
                html += "</td>\n"
            }
            html += "</tr>\n"
        }
    }

    private func alignmentStyle(for columnIndex: Int, in table: Table?) -> String {
        guard let table = table,
              columnIndex < table.columnAlignments.count else {
            return ""
        }
        let alignment = table.columnAlignments[columnIndex]
        switch alignment {
        case .left:
            return " style=\"text-align: left;\""
        case .center:
            return " style=\"text-align: center;\""
        case .right:
            return " style=\"text-align: right;\""
        case nil:
            return ""
        }
    }
}
