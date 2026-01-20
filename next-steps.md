# SwiftMark Next Steps

## Current State

SwiftMark has a solid foundation with:
- **MarkdownProcessor**: Parses markdown files with YAML frontmatter via Yams
- **SyntaxHighlighter**: Swift syntax highlighting using Splash (other languages get CSS class fallback)
- **ShortcodeProcessor**: Hugo-style shortcodes (blink, marquee, youtube, image, alert, counter, rainbow)
- **AttributedStringRenderer**: Native NSAttributedString output for AppKit/UIKit
- **Page/FrontMatter**: Data models for processed content

## Recommended Next Steps

### Phase 1: Foundation Improvements

#### 1. Add Tests
The library has no test target. This is the single most important improvement before adding features.

```swift
// In Package.swift, add:
.testTarget(
    name: "SwiftMarkTests",
    dependencies: ["SwiftMark"]
)
```

Priority test coverage:
- Frontmatter parsing (edge cases, malformed YAML)
- Shortcode regex patterns (nested shortcodes, escaped characters)
- HTML escaping completeness
- Markdown rendering for all supported elements

#### 2. Strict Mode (CommonMark Compliance)
Marked as `!important` in the project notes. This should be a configuration option.

```swift
public struct MarkdownOptions {
    public var strictMode: Bool = false  // CommonMark-compliant parsing
    public var enableShortcodes: Bool = true
    public var syntaxHighlighting: Bool = true
}
```

When `strictMode` is enabled, disable extensions and shortcodes that break CommonMark spec.

#### 3. Missing Markdown Elements
The current `MarkdownHTMLRenderer` doesn't handle:
- Images (`visitImage`)
- Thematic breaks / horizontal rules (`visitThematicBreak`)
- HTML blocks (`visitHTMLBlock`)
- Strikethrough (if using GitHub-flavored markdown)

---

### Phase 2: Extensions (marked as !important)

#### 4. Tables Support
swift-markdown supports tables. Add rendering:

```swift
mutating func visitTable(_ table: Table) { ... }
mutating func visitTableHead(_ head: TableHead) { ... }
mutating func visitTableBody(_ body: TableBody) { ... }
mutating func visitTableRow(_ row: TableRow) { ... }
mutating func visitTableCell(_ cell: TableCell) { ... }
```

#### 5. Task Lists
GitHub-style task lists `- [ ]` and `- [x]`:

```swift
mutating func visitListItem(_ listItem: ListItem) {
    if let checkbox = listItem.checkbox {
        // Render checkbox state
    }
    // ...
}
```

#### 6. Footnotes
Add footnote reference and definition handling. This may require a two-pass approach to collect definitions before rendering references.

---

### Phase 3: Architecture & Performance

#### 7. Expose the AST
Currently the AST is internal. Expose it for consumers who want programmatic access:

```swift
public func parse(_ content: String) -> (frontMatter: FrontMatter?, document: Document)
```

#### 8. Reduce Memory Allocations
Per the project goals. Profile and optimize:
- Avoid repeated string concatenation (use array + joined)
- Cache compiled regex patterns in ShortcodeProcessor
- Consider using `Substring` where possible

#### 9. Configurable Highlighter
Splash only handles Swift. Options:
- Add more Splash grammars if available
- Integrate with tree-sitter for polyglot highlighting
- Improve the fallback CSS class output for client-side libraries (Prism.js, highlight.js)

---

### Phase 4: API Polish

#### 10. Error Handling
Currently errors are silently handled with defaults. Add proper error types:

```swift
public enum SwiftMarkError: Error {
    case invalidFrontMatter(String)
    case shortcodeError(name: String, message: String)
    case fileReadError(URL, underlying: Error)
}
```

#### 11. Async File Processing
For processing multiple files:

```swift
public func process(files: [URL], relativeTo baseURL: URL) async throws -> [Page]
```

#### 12. Documentation
Add DocC documentation for the public API before releasing as a standalone package.

---

### Phase 5: Experimental

#### 13. Custom Formatting Rules
From the roadmap. Consider a plugin/visitor pattern:

```swift
public protocol MarkdownTransformer {
    func transform(_ document: Document) -> Document
}
```

#### 14. "Fork Markdown?"
The notes mention this cryptically. If the goal is a custom markdown dialect:
- Define the spec differences clearly first
- Consider whether it's better as extensions to CommonMark or a true fork
- Look at what MDX, Markdoc, and other extended markdown formats have done

---

## Suggested Priority Order

1. **Tests** - Can't safely change anything without them
2. **Missing markdown elements** - Low effort, high value
3. **Strict mode flag** - Important per project notes
4. **Tables** - High demand feature
5. **Task lists** - High demand feature
6. **Error handling** - Better developer experience
7. **AST exposure** - Enables advanced use cases
8. **Performance profiling** - Measure before optimizing

---

## Quick Wins

These can be done in a single session:

- [ ] Add `visitImage` to both renderers
- [ ] Add `visitThematicBreak` to both renderers
- [ ] Cache regex patterns in `ShortcodeProcessor` (compile once in init)
- [ ] Add test target to Package.swift
- [ ] Make `htmlEscaped` extension `public` (currently internal, but useful)
