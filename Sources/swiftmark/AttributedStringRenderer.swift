import Foundation
import Markdown

#if canImport(AppKit)
    import AppKit
#elseif canImport(UIKit)
    import UIKit
#endif

/// Renders markdown documents as NSAttributedString for rich text display
public class AttributedStringRenderer {

    // MARK: - Text Styles

    fileprivate struct TextStyle {
        // Base font - slightly larger for better readability
        nonisolated(unsafe) static let baseFont: Font = {
            #if canImport(AppKit)
                return NSFont.systemFont(ofSize: 16, weight: .regular)
            #else
                return UIFont.systemFont(ofSize: 16, weight: .regular)
            #endif
        }()

        nonisolated(unsafe) static let monoFont: Font = {
            #if canImport(AppKit)
                return NSFont.monospacedSystemFont(ofSize: 15, weight: .regular)
            #else
                return UIFont.monospacedSystemFont(ofSize: 15, weight: .regular)
            #endif
        }()

        static func heading(level: Int) -> Font {
            let sizes: [CGFloat] = [32, 26, 22, 19, 17, 16]
            let weights: [Font.Weight] = [.bold, .bold, .semibold, .semibold, .medium, .medium]
            let size = sizes[min(level - 1, 5)]
            let weight = weights[min(level - 1, 5)]
            #if canImport(AppKit)
                return NSFont.systemFont(ofSize: size, weight: weight)
            #else
                return UIFont.systemFont(ofSize: size, weight: weight)
            #endif
        }

        static let baseColor: Color = {
            #if canImport(AppKit)
                return NSColor.textColor
            #else
                return UIColor.label
            #endif
        }()

        static let secondaryColor: Color = {
            #if canImport(AppKit)
                return NSColor.secondaryLabelColor
            #else
                return UIColor.secondaryLabel
            #endif
        }()

        static let codeBackgroundColor: Color = {
            #if canImport(AppKit)
                return NSColor(white: 0.15, alpha: 1.0)  // Dark gray for code blocks
            #else
                return UIColor.systemGray5
            #endif
        }()

        static let codeTextColor: Color = {
            #if canImport(AppKit)
                return NSColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0)  // Light blue
            #else
                return UIColor.systemBlue
            #endif
        }()

        static let quoteBarColor: Color = {
            #if canImport(AppKit)
                return NSColor(white: 0.4, alpha: 1.0)  // Medium gray for quote bar
            #else
                return UIColor.systemGray
            #endif
        }()
    }

    #if canImport(AppKit)
        typealias Font = NSFont
        typealias Color = NSColor
    #else
        typealias Font = UIFont
        typealias Color = UIColor
    #endif

    public init() {}

    // MARK: - Public API

    /// Render markdown string to attributed string
    public func render(_ markdown: String) -> NSAttributedString {
        let document = Document(parsing: markdown)
        var walker = AttributedStringWalker()
        return walker.render(document)
    }

    /// Extract markdown from attributed string
    /// Note: This is a best-effort conversion and may not preserve all formatting
    public func extractMarkdown(from attributedString: NSAttributedString) -> String {
        var markdown = ""
        let fullRange = NSRange(location: 0, length: attributedString.length)

        attributedString.enumerateAttributes(in: fullRange, options: []) { attributes, range, _ in
            let substring = attributedString.attributedSubstring(from: range).string

            // Check for heading
            if let font = attributes[.font] as? Font {
                let fontSize = font.pointSize
                if fontSize >= 20 {
                    let level = fontSize >= 28 ? 1 : fontSize >= 24 ? 2 : fontSize >= 20 ? 3 : 4
                    markdown += String(repeating: "#", count: level) + " " + substring + "\n\n"
                    return
                }
            }

            // Check for bold
            var text = substring
            if let font = attributes[.font] as? Font {
                #if canImport(AppKit)
                    if font.fontDescriptor.symbolicTraits.contains(.bold) {
                        text = "**\(text)**"
                    }
                    if font.fontDescriptor.symbolicTraits.contains(.italic) {
                        text = "*\(text)*"
                    }
                #else
                    if font.fontDescriptor.symbolicTraits.contains(.traitBold) {
                        text = "**\(text)**"
                    }
                    if font.fontDescriptor.symbolicTraits.contains(.traitItalic) {
                        text = "*\(text)*"
                    }
                #endif
            }

            // Check for code
            if let font = attributes[.font] as? Font, font.familyName?.contains("Mono") == true {
                text = "`\(substring)`"
            }

            markdown += text
        }

        return markdown
    }
}

// MARK: - Attributed String Walker

private struct AttributedStringWalker: MarkupWalker {
    private var attributedString = NSMutableAttributedString()
    private var currentAttributes: [NSAttributedString.Key: Any] = [:]

    init() {
        // Set base attributes
        currentAttributes[.font] = AttributedStringRenderer.TextStyle.baseFont
        currentAttributes[.foregroundColor] = AttributedStringRenderer.TextStyle.baseColor
    }

    mutating func render(_ document: Document) -> NSAttributedString {
        attributedString = NSMutableAttributedString()
        visit(document)
        return attributedString
    }

    // MARK: - Block Elements

    mutating func visitHeading(_ heading: Heading) {
        let font = AttributedStringRenderer.TextStyle.heading(level: heading.level)
        let savedAttributes = currentAttributes
        currentAttributes[.font] = font

        descendInto(heading)
        appendNewlines(2)

        currentAttributes = savedAttributes
    }

    mutating func visitParagraph(_ paragraph: Paragraph) {
        // Add paragraph spacing attribute
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = 8
        paragraphStyle.lineSpacing = 2
        currentAttributes[.paragraphStyle] = paragraphStyle

        descendInto(paragraph)
        appendNewlines(1)

        currentAttributes.removeValue(forKey: .paragraphStyle)
    }

    mutating func visitBlockQuote(_ blockQuote: BlockQuote) {
        let savedAttributes = currentAttributes
        currentAttributes[.foregroundColor] = AttributedStringRenderer.TextStyle.secondaryColor

        // Add quote indicator
        append("  ┃ ", with: currentAttributes)

        descendInto(blockQuote)
        appendNewlines(2)

        currentAttributes = savedAttributes
    }

    mutating func visitCodeBlock(_ codeBlock: CodeBlock) {
        let font = AttributedStringRenderer.TextStyle.monoFont
        var attributes = currentAttributes
        attributes[.font] = font
        attributes[.backgroundColor] = AttributedStringRenderer.TextStyle.codeBackgroundColor
        attributes[.foregroundColor] = AttributedStringRenderer.TextStyle.codeTextColor

        // Add padding around code block
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = 12
        paragraphStyle.paragraphSpacingBefore = 8
        paragraphStyle.firstLineHeadIndent = 12
        paragraphStyle.headIndent = 12
        paragraphStyle.tailIndent = -12
        attributes[.paragraphStyle] = paragraphStyle

        append("\n" + codeBlock.code + "\n", with: attributes)
        appendNewlines(1)
    }

    mutating func visitUnorderedList(_ unorderedList: UnorderedList) {
        descendInto(unorderedList)
        appendNewlines(1)
    }

    mutating func visitOrderedList(_ orderedList: OrderedList) {
        descendInto(orderedList)
        appendNewlines(1)
    }

    mutating func visitListItem(_ listItem: ListItem) {
        // Add bullet or number
        append("  • ", with: currentAttributes)
        descendInto(listItem)
        appendNewlines(1)
    }

    // MARK: - Inline Elements

    mutating func visitText(_ text: Text) {
        append(text.string, with: currentAttributes)
    }

    mutating func visitStrong(_ strong: Strong) {
        let savedFont = currentAttributes[.font] as? AttributedStringRenderer.Font

        #if canImport(AppKit)
            if let font = savedFont {
                let boldFont =
                    NSFont(
                        descriptor: font.fontDescriptor.withSymbolicTraits(.bold),
                        size: font.pointSize) ?? font
                currentAttributes[.font] = boldFont
            }
        #else
            if let font = savedFont {
                let boldFont = UIFont(
                    descriptor: font.fontDescriptor.withSymbolicTraits(.traitBold)
                        ?? font.fontDescriptor, size: font.pointSize)
                currentAttributes[.font] = boldFont
            }
        #endif

        descendInto(strong)

        currentAttributes[.font] = savedFont
    }

    mutating func visitEmphasis(_ emphasis: Emphasis) {
        let savedFont = currentAttributes[.font] as? AttributedStringRenderer.Font

        #if canImport(AppKit)
            if let font = savedFont {
                let italicFont =
                    NSFont(
                        descriptor: font.fontDescriptor.withSymbolicTraits(.italic),
                        size: font.pointSize) ?? font
                currentAttributes[.font] = italicFont
            }
        #else
            if let font = savedFont {
                let italicFont = UIFont(
                    descriptor: font.fontDescriptor.withSymbolicTraits(.traitItalic)
                        ?? font.fontDescriptor, size: font.pointSize)
                currentAttributes[.font] = italicFont
            }
        #endif

        descendInto(emphasis)

        currentAttributes[.font] = savedFont
    }

    mutating func visitInlineCode(_ inlineCode: InlineCode) {
        var attributes = currentAttributes
        attributes[.font] = AttributedStringRenderer.TextStyle.monoFont
        attributes[.backgroundColor] = AttributedStringRenderer.TextStyle.codeBackgroundColor
        attributes[.foregroundColor] = AttributedStringRenderer.TextStyle.codeTextColor

        append(" " + inlineCode.code + " ", with: attributes)
    }

    mutating func visitLink(_ link: Link) {
        let savedAttributes = currentAttributes

        #if canImport(AppKit)
            currentAttributes[.foregroundColor] = NSColor.linkColor
        #else
            currentAttributes[.foregroundColor] = UIColor.link
        #endif

        if let destination = link.destination {
            currentAttributes[.link] = destination
        }

        descendInto(link)

        currentAttributes = savedAttributes
    }

    mutating func visitLineBreak(_ lineBreak: LineBreak) {
        appendNewlines(1)
    }

    mutating func visitSoftBreak(_ softBreak: SoftBreak) {
        append(" ", with: currentAttributes)
    }

    mutating func visitImage(_ image: Image) {
        // For attributed strings, represent images as placeholder text with link
        // Full image rendering would require NSTextAttachment which is more complex
        let alt = image.plainText.isEmpty ? "image" : image.plainText
        var attributes = currentAttributes

        #if canImport(AppKit)
            attributes[.foregroundColor] = NSColor.linkColor
        #else
            attributes[.foregroundColor] = UIColor.link
        #endif

        if let source = image.source {
            attributes[.link] = source
        }

        append("[\(alt)]", with: attributes)
    }

    mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) {
        var attributes = currentAttributes
        attributes[.foregroundColor] = AttributedStringRenderer.TextStyle.secondaryColor
        append("\n─────────────────────────────────\n", with: attributes)
    }

    // MARK: - Helper Methods

    private mutating func append(_ string: String, with attributes: [NSAttributedString.Key: Any]) {
        let attrString = NSAttributedString(string: string, attributes: attributes)
        attributedString.append(attrString)
    }

    private mutating func appendNewlines(_ count: Int) {
        let newlines = String(repeating: "\n", count: count)
        append(newlines, with: currentAttributes)
    }
}
