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
