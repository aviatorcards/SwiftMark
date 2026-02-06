import Testing
@testable import SwiftMark

@Suite("MarkdownProcessor Tests")
struct MarkdownProcessorTests {
    let processor = MarkdownProcessor()

    @Test("Renders basic markdown to HTML")
    func basicMarkdown() {
        let (_, html) = processor.process(content: "# Hello World")
        #expect(html.contains("<h1>Hello World</h1>"))
    }

    @Test("Renders paragraphs")
    func paragraphs() {
        let (_, html) = processor.process(content: "This is a paragraph.")
        #expect(html.contains("<p>This is a paragraph.</p>"))
    }

    @Test("Renders emphasis and strong")
    func emphasisAndStrong() {
        let (_, html) = processor.process(content: "This is *italic* and **bold**.")
        #expect(html.contains("<em>italic</em>"))
        #expect(html.contains("<strong>bold</strong>"))
    }

    @Test("Renders code blocks")
    func codeBlocks() {
        let markdown = """
        ```swift
        let x = 1
        ```
        """
        let (_, html) = processor.process(content: markdown)
        #expect(html.contains("language-swift"))
        #expect(html.contains("let"))
    }

    @Test("Renders inline code")
    func inlineCode() {
        let (_, html) = processor.process(content: "Use `let` for constants.")
        #expect(html.contains("<code>let</code>"))
    }

    @Test("Renders links")
    func links() {
        let (_, html) = processor.process(content: "[Example](https://example.com)")
        #expect(html.contains("<a href=\"https://example.com\">Example</a>"))
    }

    @Test("Renders unordered lists")
    func unorderedLists() {
        let markdown = """
        - Item 1
        - Item 2
        """
        let (_, html) = processor.process(content: markdown)
        #expect(html.contains("<ul>"))
        #expect(html.contains("<li>"))
    }

    @Test("Renders ordered lists")
    func orderedLists() {
        let markdown = """
        1. First
        2. Second
        """
        let (_, html) = processor.process(content: markdown)
        #expect(html.contains("<ol>"))
        #expect(html.contains("<li>"))
    }

    @Test("Renders blockquotes")
    func blockquotes() {
        let (_, html) = processor.process(content: "> This is a quote")
        #expect(html.contains("<blockquote>"))
    }

    @Test("Renders images")
    func images() {
        let (_, html) = processor.process(content: "![Alt text](image.png)")
        #expect(html.contains("<img"))
        #expect(html.contains("src=\"image.png\""))
        #expect(html.contains("alt=\"Alt text\""))
    }

    @Test("Renders thematic breaks")
    func thematicBreaks() {
        let (_, html) = processor.process(content: "Above\n\n---\n\nBelow")
        #expect(html.contains("<hr"))
    }

    @Test("Escapes ampersands in text")
    func htmlEscaping() {
        // Ampersands must be escaped in HTML content
        let (_, html) = processor.process(content: "Use A & B carefully")
        #expect(html.contains("&amp;"))
    }
}

@Suite("FrontMatter Tests")
struct FrontMatterTests {
    let processor = MarkdownProcessor()

    @Test("Parses YAML frontmatter")
    func parsesFrontmatter() {
        let markdown = """
        ---
        title: My Post
        description: A test post
        ---
        # Content here
        """
        let (frontMatter, _) = processor.process(content: markdown)
        #expect(frontMatter?.title == "My Post")
        #expect(frontMatter?.description == "A test post")
    }

    @Test("Handles missing frontmatter")
    func missingFrontmatter() {
        let (frontMatter, html) = processor.process(content: "# Just content")
        #expect(frontMatter == nil)
        #expect(html.contains("<h1>Just content</h1>"))
    }

    @Test("Parses tags array")
    func parsesTagsArray() {
        let markdown = """
        ---
        title: Tagged Post
        tags:
          - swift
          - markdown
        ---
        Content
        """
        let (frontMatter, _) = processor.process(content: markdown)
        #expect(frontMatter?.tags == ["swift", "markdown"])
    }
}

@Suite("ShortcodeProcessor Tests")
struct ShortcodeProcessorTests {
    let processor = ShortcodeProcessor()

    @Test("Processes YouTube shortcode")
    func youtubeShortcode() {
        let input = "{{< youtube id=\"abc123\" >}}"
        let output = processor.process(input)
        #expect(output.contains("youtube.com/embed/abc123"))
        #expect(output.contains("iframe"))
    }

    @Test("Processes paired shortcode with content")
    func pairedShortcode() {
        let input = "{{< blink >}}Hello{{< /blink >}}"
        let output = processor.process(input)
        #expect(output.contains("Hello"))
        #expect(output.contains("blink"))
    }

    @Test("Processes alert shortcode")
    func alertShortcode() {
        let input = "{{< alert type=\"warning\" title=\"Heads up\" >}}Be careful{{< /alert >}}"
        let output = processor.process(input)
        #expect(output.contains("alert-warning"))
        #expect(output.contains("Heads up"))
        #expect(output.contains("Be careful"))
    }

    @Test("Handles self-closing shortcode")
    func selfClosingShortcode() {
        let input = "{{< counter style=\"digital\" />}}"
        let output = processor.process(input)
        #expect(output.contains("visitor-counter"))
    }

    @Test("Ignores unknown shortcodes")
    func unknownShortcode() {
        let input = "{{< unknown param=\"value\" >}}"
        let output = processor.process(input)
        #expect(output == input)
    }
}

@Suite("SyntaxHighlighter Tests")
struct SyntaxHighlighterTests {
    let highlighter = SyntaxHighlighter()

    @Test("Highlights Swift code")
    func highlightsSwift() {
        let code = "let x = 42"
        let output = highlighter.highlight(code: code, language: "swift")
        #expect(output.contains("language-swift"))
        #expect(output.contains("<span"))
    }

    @Test("Falls back for unknown languages")
    func fallbackForUnknown() {
        let code = "console.log('hello')"
        let output = highlighter.highlight(code: code, language: "javascript")
        #expect(output.contains("language-javascript"))
        #expect(output.contains("<pre><code"))
    }
}

@Suite("String HTML Escaping Tests")
struct HTMLEscapingTests {
    @Test("Escapes ampersand")
    func escapesAmpersand() {
        #expect("A & B".htmlEscaped == "A &amp; B")
    }

    @Test("Escapes angle brackets")
    func escapesAngleBrackets() {
        #expect("<tag>".htmlEscaped == "&lt;tag&gt;")
    }

    @Test("Escapes quotes")
    func escapesQuotes() {
        #expect("\"quoted\"".htmlEscaped == "&quot;quoted&quot;")
        #expect("it's".htmlEscaped == "it&#39;s")
    }

    @Test("Handles multiple escapes")
    func multipleEscapes() {
        let input = "<script>alert('xss' & \"more\")</script>"
        let escaped = input.htmlEscaped
        #expect(!escaped.contains("<"))
        #expect(!escaped.contains(">"))
        #expect(escaped.contains("&lt;"))
        #expect(escaped.contains("&gt;"))
    }
}

// MARK: - GFM Extensions Tests

@Suite("Table Rendering Tests")
struct TableTests {
    let processor = MarkdownProcessor()

    @Test("Renders basic table")
    func basicTable() {
        let markdown = """
        | Header 1 | Header 2 |
        |----------|----------|
        | Cell 1   | Cell 2   |
        | Cell 3   | Cell 4   |
        """
        let (_, html) = processor.process(content: markdown)
        #expect(html.contains("<table>"))
        #expect(html.contains("<thead>"))
        #expect(html.contains("<tbody>"))
        #expect(html.contains("<th>"))
        #expect(html.contains("<td>"))
        #expect(html.contains("Header 1"))
        #expect(html.contains("Cell 1"))
    }

    @Test("Renders table with alignment")
    func tableWithAlignment() {
        let markdown = """
        | Left | Center | Right |
        |:-----|:------:|------:|
        | A    | B      | C     |
        """
        let (_, html) = processor.process(content: markdown)
        #expect(html.contains("text-align: left"))
        #expect(html.contains("text-align: center"))
        #expect(html.contains("text-align: right"))
    }
}

@Suite("Strikethrough Tests")
struct StrikethroughTests {
    let processor = MarkdownProcessor()

    @Test("Renders strikethrough text")
    func strikethroughText() {
        let (_, html) = processor.process(content: "This is ~~deleted~~ text.")
        #expect(html.contains("<del>deleted</del>"))
    }
}

@Suite("Task List Tests")
struct TaskListTests {
    let processor = MarkdownProcessor()

    @Test("Renders unchecked task item")
    func uncheckedTask() {
        let markdown = """
        - [ ] Unchecked item
        """
        let (_, html) = processor.process(content: markdown)
        #expect(html.contains("<input type=\"checkbox\" disabled"))
        #expect(!html.contains("checked disabled"))  // Should NOT have "checked" before "disabled"
    }

    @Test("Renders checked task item")
    func checkedTask() {
        let markdown = """
        - [x] Checked item
        """
        let (_, html) = processor.process(content: markdown)
        #expect(html.contains("<input type=\"checkbox\" checked disabled"))
    }

    @Test("Renders mixed task list")
    func mixedTaskList() {
        let markdown = """
        - [x] Done
        - [ ] Todo
        - Regular item
        """
        let (_, html) = processor.process(content: markdown)
        #expect(html.contains("checked disabled"))
        #expect(html.contains("<li>"))
    }
}

// MARK: - MarkdownOptions Tests

@Suite("MarkdownOptions Tests")
struct MarkdownOptionsTests {
    @Test("Default options enable all features")
    func defaultOptions() {
        let options = MarkdownOptions.default
        #expect(options.strictMode == false)
        #expect(options.enableShortcodes == true)
        #expect(options.syntaxHighlighting == true)
    }

    @Test("Strict options disable GFM features")
    func strictOptions() {
        let options = MarkdownOptions.strict
        #expect(options.strictMode == true)
        #expect(options.enableShortcodes == false)
    }

    @Test("Strict mode disables strikethrough rendering")
    func strictModeStrikethrough() {
        let processor = MarkdownProcessor(options: .strict)
        let (_, html) = processor.process(content: "This is ~~deleted~~ text.")
        #expect(!html.contains("<del>"))
        #expect(html.contains("deleted"))
    }

    @Test("Strict mode disables task list checkboxes")
    func strictModeTaskList() {
        let processor = MarkdownProcessor(options: .strict)
        let markdown = """
        - [x] Item
        """
        let (_, html) = processor.process(content: markdown)
        #expect(!html.contains("<input"))
        #expect(html.contains("<li>"))
    }

    @Test("Strict mode renders tables as plain text")
    func strictModeTables() {
        let processor = MarkdownProcessor(options: .strict)
        let markdown = """
        | A | B |
        |---|---|
        | 1 | 2 |
        """
        let (_, html) = processor.process(content: markdown)
        #expect(!html.contains("<table>"))
    }

    @Test("Disabling shortcodes leaves them unprocessed")
    func disableShortcodes() {
        let options = MarkdownOptions(enableShortcodes: false)
        let processor = MarkdownProcessor(options: options)
        let (_, html) = processor.process(content: "{{< youtube id=\"abc\" >}}")
        #expect(!html.contains("iframe"))
        #expect(html.contains("youtube"))
    }

    @Test("Disabling syntax highlighting uses plain code blocks")
    func disableSyntaxHighlighting() {
        let options = MarkdownOptions(syntaxHighlighting: false)
        let processor = MarkdownProcessor(options: options)
        let markdown = """
        ```swift
        let x = 1
        ```
        """
        let (_, html) = processor.process(content: markdown)
        #expect(html.contains("language-swift"))
        #expect(!html.contains("<span style="))
    }
}
