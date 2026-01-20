# SwiftMark

A Swift library for parsing and rendering Markdown with YAML frontmatter support, shortcode processing, and syntax highlighting.

## Features

- **Markdown to HTML**: Full markdown rendering using Apple's swift-markdown
- **Markdown to NSAttributedString**: Native rich text output for AppKit/UIKit
- **YAML Frontmatter**: Parse metadata from markdown files using Yams
- **Syntax Highlighting**: Swift code highlighting via Splash (CSS class fallback for other languages)
- **Shortcodes**: Hugo-style shortcode support with built-in and custom shortcodes

## Requirements

- macOS 13+ / iOS 16+
- Swift 6.0+

## Installation

Add SwiftMark to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/aviatorcards/SwiftMark.git", from: "1.0.0")
]
```

Then add it to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: ["SwiftMark"]
)
```

## Usage

### Basic Markdown Processing

```swift
import SwiftMark

let processor = MarkdownProcessor()

// Process markdown to HTML
let markdown = """
# Hello World

This is **bold** and *italic* text.
"""

let (frontMatter, html) = processor.process(content: markdown)
print(html)
// <h1>Hello World</h1>
// <p>This is <strong>bold</strong> and <em>italic</em> text.</p>
```

### With Frontmatter

```swift
let markdown = """
---
title: My Post
description: A sample post
tags:
  - swift
  - markdown
---
# Content Here

The actual content of the post.
"""

let (frontMatter, html) = processor.process(content: markdown)
print(frontMatter?.title)       // "My Post"
print(frontMatter?.description) // "A sample post"
print(frontMatter?.tags)        // ["swift", "markdown"]
```

### Attributed String Output

For native text rendering in AppKit/UIKit:

```swift
let (frontMatter, attributedString) = processor.processToAttributedString(content: markdown)
// Use attributedString with NSTextView, UITextView, etc.
```

### Processing Files

```swift
let fileURL = URL(fileURLWithPath: "/path/to/post.md")
let baseURL = URL(fileURLWithPath: "/path/to")

let page = try processor.process(file: fileURL, relativeTo: baseURL)
print(page.displayTitle)  // Title from frontmatter or derived from filename
print(page.content)       // Rendered HTML
print(page.rawMarkdown)   // Original markdown source
```

### Shortcodes

SwiftMark supports Hugo-style shortcodes:

```markdown
{{< youtube id="dQw4w9WgXcQ" >}}

{{< alert type="warning" title="Note" >}}
This is a warning message.
{{< /alert >}}

{{< image src="photo.jpg" alt="A photo" caption="My caption" >}}
```

#### Built-in Shortcodes

| Shortcode | Description | Parameters |
|-----------|-------------|------------|
| `youtube` | YouTube embed | `id`, `width`, `height` |
| `image` | Image with caption | `src`, `alt`, `caption`, `width`, `align` |
| `alert` | Callout box | `type` (info/warning/error/success), `title` |
| `blink` | Blinking text | content |
| `marquee` | Scrolling text | `direction`, `speed` |
| `counter` | Visitor counter | `style` (digital/text) |
| `rainbow` | Rainbow colored text | content |

#### Custom Shortcodes

```swift
struct MyShortcode: Shortcode {
    let name = "greeting"

    func render(params: [String: String], content: String?) -> String {
        let name = params["name"] ?? "World"
        return "<p>Hello, \(name.htmlEscaped)!</p>"
    }
}

let processor = ShortcodeProcessor()
processor.register(MyShortcode())
```

### Syntax Highlighting

Swift code blocks are highlighted automatically:

```swift
let highlighter = SyntaxHighlighter()
let highlighted = highlighter.highlight(code: "let x = 42", language: "swift")
// Returns HTML with inline color styles
```

Other languages receive CSS classes for client-side highlighting:

```html
<pre><code class="language-javascript">console.log('hello')</code></pre>
```

### HTML Escaping

The `htmlEscaped` string extension is public for your use:

```swift
let unsafe = "<script>alert('xss')</script>"
let safe = unsafe.htmlEscaped
// "&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;"
```

## Dependencies

- [swift-markdown](https://github.com/apple/swift-markdown) - Apple's Markdown parser
- [Yams](https://github.com/jpsim/Yams) - YAML parsing
- [Splash](https://github.com/JohnSundell/Splash) - Swift syntax highlighting

Hoping to remove all dependencies.

## License

GPL AFAIK
