import Testing
import Foundation
@testable import SwiftMark

#if canImport(AppKit)
import AppKit
typealias Font = NSFont
typealias Color = NSColor
#elseif canImport(UIKit)
import UIKit
typealias Font = UIFont
typealias Color = UIColor
#endif

@Suite("AttributedStringRenderer Tests")
struct AttributedStringRendererTests {
    let renderer = AttributedStringRenderer()

    @Test("Renders basic text")
    func basicText() {
        let attributedString = renderer.render("Hello World", options: .default)
        #expect(attributedString.string.contains("Hello World"))
    }

    @Test("Renders bold text")
    func boldText() {
        let attributedString = renderer.render("This is **bold**", options: .default)
        let fullString = attributedString.string
        guard let range = fullString.range(of: "bold") else {
            Issue.record("Could not find 'bold' in output")
            return
        }
        
        let nsRange = NSRange(range, in: fullString)
        let attributes = attributedString.attributes(at: nsRange.location, effectiveRange: nil)
        
        if let font = attributes[.font] as? Font {
            #if canImport(AppKit)
            #expect(font.fontDescriptor.symbolicTraits.contains(.bold))
            #else
            #expect(font.fontDescriptor.symbolicTraits.contains(.traitBold))
            #endif
        } else {
            Issue.record("No font attribute found for bold text")
        }
    }

    @Test("Renders italic text")
    func italicText() {
        let attributedString = renderer.render("This is *italic*", options: .default)
        let fullString = attributedString.string
        guard let range = fullString.range(of: "italic") else {
            Issue.record("Could not find 'italic' in output")
            return
        }
        
        let nsRange = NSRange(range, in: fullString)
        let attributes = attributedString.attributes(at: nsRange.location, effectiveRange: nil)
        
        if let font = attributes[.font] as? Font {
            #if canImport(AppKit)
            #expect(font.fontDescriptor.symbolicTraits.contains(.italic))
            #else
            #expect(font.fontDescriptor.symbolicTraits.contains(.traitItalic))
            #endif
        } else {
            Issue.record("No font attribute found for italic text")
        }
    }

    @Test("Renders headings")
    func headings() {
        let attributedString = renderer.render("# Heading 1", options: .default)
        let fullString = attributedString.string
        guard let range = fullString.range(of: "Heading 1") else {
            Issue.record("Could not find 'Heading 1' in output")
            return
        }
        
        let nsRange = NSRange(range, in: fullString)
        let attributes = attributedString.attributes(at: nsRange.location, effectiveRange: nil)
        
        if let font = attributes[.font] as? Font {
            #expect(font.pointSize >= 28)
        } else {
            Issue.record("No font attribute found for heading")
        }
    }

    @Test("Renders links")
    func links() {
        let attributedString = renderer.render("[Swift](https://swift.org)", options: .default)
        let fullString = attributedString.string
        guard let range = fullString.range(of: "Swift") else {
            Issue.record("Could not find 'Swift' in output")
            return
        }
        
        let nsRange = NSRange(range, in: fullString)
        let attributes = attributedString.attributes(at: nsRange.location, effectiveRange: nil)
        
        #expect(attributes[.link] != nil)
        if let link = attributes[.link] as? String {
            #expect(link == "https://swift.org")
        } else if let link = attributes[.link] as? URL {
            #expect(link.absoluteString == "https://swift.org")
        }
    }

    @Test("Renders code blocks")
    func codeBlocks() {
        let markdown = """
        ```
        let x = 1
        ```
        """
        let attributedString = renderer.render(markdown, options: .default)
        let fullString = attributedString.string
        guard let range = fullString.range(of: "let x = 1") else {
            Issue.record("Could not find code in output")
            return
        }
        
        let nsRange = NSRange(range, in: fullString)
        let attributes = attributedString.attributes(at: nsRange.location, effectiveRange: nil)
        
        if let font = attributes[.font] as? Font {
            #expect(font.familyName?.contains("Mono") == true || font.fontDescriptor.symbolicTraits.contains(.monoSpace))
        }
        #expect(attributes[.backgroundColor] != nil)
    }

    @Test("Extracts markdown from attributed string")
    func extraction() {
        let input = "This is **bold** and *italic*."
        let attributedString = renderer.render(input, options: .default)
        let extracted = renderer.extractMarkdown(from: attributedString)
        
        #expect(extracted.contains("**bold**"))
        #expect(extracted.contains("*italic*"))
    }
}