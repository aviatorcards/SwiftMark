import Foundation

/// Processes shortcodes in markdown content
public class ShortcodeProcessor {
    private var shortcodes: [String: Shortcode] = [:]

    // Cached regex patterns for performance
    private let pairedRegex: NSRegularExpression?
    private let selfClosingRegex: NSRegularExpression?
    private let emptyRegex: NSRegularExpression?
    private let shortcodeTagRegex: NSRegularExpression?
    private let parameterRegex: NSRegularExpression?

    public init() {
        // Compile regex patterns once at initialization
        let pairedPattern = #"\{\{<\s*(\w+)(.*?)>\}\}(.*?)\{\{<\s*/\1\s*>\}\}"#
        let selfClosingPattern = #"\{\{<\s*(\w+)(.*?)/>\}\}"#
        let emptyPattern = #"\{\{<\s*(\w+)(.*?)>\}\}"#
        let shortcodeTagPattern = #"\{\{&lt;(.*?)&gt;\}\}"#
        let parameterPattern = #"(\w+)=["']([^"']*)["']"#

        pairedRegex = try? NSRegularExpression(pattern: pairedPattern, options: [.dotMatchesLineSeparators])
        selfClosingRegex = try? NSRegularExpression(pattern: selfClosingPattern, options: [])
        emptyRegex = try? NSRegularExpression(pattern: emptyPattern, options: [])
        shortcodeTagRegex = try? NSRegularExpression(pattern: shortcodeTagPattern, options: [.dotMatchesLineSeparators])
        parameterRegex = try? NSRegularExpression(pattern: parameterPattern, options: [])

        registerBuiltInShortcodes()
    }

    /// Register built-in shortcodes
    private func registerBuiltInShortcodes() {
        register(BlinkShortcode())
        register(MarqueeShortcode())
        register(YouTubeShortcode())
        register(ImageShortcode())
        register(AlertShortcode())
        register(CounterShortcode())
        register(RainbowTextShortcode())
    }

    /// Register a custom shortcode
    public func register(_ shortcode: Shortcode) {
        shortcodes[shortcode.name] = shortcode
    }

    /// Process all shortcodes in markdown content
    public func process(_ markdown: String) -> String {
        // Decode HTML entities in shortcode tags so we can use simpler patterns
        var result = decodeShortcodeTags(markdown)

        // Process paired tags first
        if let regex = pairedRegex {
            // Keep processing until no more matches (for nested or overlapping replacements)
            var didReplace = true
            var iterations = 0
            let maxIterations = 100  // Safety limit

            while didReplace && iterations < maxIterations {
                iterations += 1
                didReplace = false

                let nsString = result as NSString
                let matches = regex.matches(
                    in: result, range: NSRange(location: 0, length: nsString.length))

                for match in matches.reversed() {
                    guard match.numberOfRanges >= 4 else { continue }

                    let shortcodeName = nsString.substring(with: match.range(at: 1))
                    let paramsString = nsString.substring(with: match.range(at: 2))
                    let content = nsString.substring(with: match.range(at: 3))

                    let params = parseParameters(from: paramsString)

                    if let shortcode = shortcodes[shortcodeName] {
                        let rendered = shortcode.render(params: params, content: content)
                        result =
                            (result as NSString).replacingCharacters(
                                in: match.range, with: rendered) as String
                        didReplace = true
                    }
                }
            }
        }

        // Process self-closing tags with slash
        if let regex = selfClosingRegex {
            var didReplace = true
            var iterations = 0
            let maxIterations = 100

            while didReplace && iterations < maxIterations {
                iterations += 1
                didReplace = false

                let nsString = result as NSString
                let matches = regex.matches(
                    in: result, range: NSRange(location: 0, length: nsString.length))

                for match in matches.reversed() {
                    guard match.numberOfRanges >= 3 else { continue }

                    let shortcodeName = nsString.substring(with: match.range(at: 1))
                    let paramsString = nsString.substring(with: match.range(at: 2))

                    let params = parseParameters(from: paramsString)

                    if let shortcode = shortcodes[shortcodeName] {
                        let rendered = shortcode.render(params: params, content: nil)
                        result =
                            (result as NSString).replacingCharacters(
                                in: match.range, with: rendered) as String
                        didReplace = true
                    }
                }
            }
        }

        // Process empty tags (no slash, no closing tag)
        if let regex = emptyRegex {
            var didReplace = true
            var iterations = 0
            let maxIterations = 100

            while didReplace && iterations < maxIterations {
                iterations += 1
                didReplace = false

                let nsString = result as NSString
                let matches = regex.matches(
                    in: result, range: NSRange(location: 0, length: nsString.length))

                for match in matches.reversed() {
                    guard match.numberOfRanges >= 3 else { continue }

                    let shortcodeName = nsString.substring(with: match.range(at: 1))
                    let paramsString = nsString.substring(with: match.range(at: 2))

                    let params = parseParameters(from: paramsString)

                    if let shortcode = shortcodes[shortcodeName] {
                        let rendered = shortcode.render(params: params, content: nil)
                        result =
                            (result as NSString).replacingCharacters(
                                in: match.range, with: rendered) as String
                        didReplace = true
                    }
                }
            }
        }

        return result
    }

    /// Decode HTML entities specifically in shortcode tags
    private func decodeShortcodeTags(_ html: String) -> String {
        // Replace HTML entities only within shortcode delimiters {{< >}}
        guard let regex = shortcodeTagRegex else {
            return html
        }

        var result = html
        let matches = regex.matches(in: html, range: NSRange(html.startIndex..., in: html))

        // Process in reverse to maintain offsets
        for match in matches.reversed() {
            let fullMatch = (html as NSString).substring(with: match.range)
            let decoded =
                fullMatch
                .replacingOccurrences(of: "&lt;", with: "<")
                .replacingOccurrences(of: "&gt;", with: ">")
                .replacingOccurrences(of: "&quot;", with: "\"")
                .replacingOccurrences(of: "&#39;", with: "'")
                .replacingOccurrences(of: "&amp;", with: "&")

            result = (result as NSString).replacingCharacters(in: match.range, with: decoded)
        }

        return result
    }

    /// Parse parameters from string like: param1="value1" param2="value2"
    /// Also handles curly quotes (U+201C, U+201D) that markdown processors may generate
    private func parseParameters(from string: String) -> [String: String] {
        var params: [String: String] = [:]

        // Convert curly quotes to straight quotes first
        let normalized =
            string
            .replacingOccurrences(of: "\u{201C}", with: "\"")  // " → "
            .replacingOccurrences(of: "\u{201D}", with: "\"")  // " → "
            .replacingOccurrences(of: "\u{2018}", with: "'")  // ' → '
            .replacingOccurrences(of: "\u{2019}", with: "'")  // ' → '

        // Match key="value" or key='value' with straight quotes
        guard let regex = parameterRegex else {
            return params
        }

        let nsString = normalized as NSString
        let matches = regex.matches(
            in: normalized, range: NSRange(location: 0, length: nsString.length))

        for match in matches {
            if match.numberOfRanges >= 3 {
                let key = nsString.substring(with: match.range(at: 1))
                let value = nsString.substring(with: match.range(at: 2))
                params[key] = value
            }
        }

        return params
    }
}

/// Protocol for shortcode implementations
public protocol Shortcode {
    var name: String { get }
    func render(params: [String: String], content: String?) -> String
}

// MARK: - Built-in Shortcodes

/// Blink text shortcode (GeoCities classic!)
struct BlinkShortcode: Shortcode {
    let name = "blink"

    func render(params: [String: String], content: String?) -> String {
        let text = (content ?? params["text"] ?? "").htmlEscaped
        return
            "<span class=\"blink-text\" style=\"animation: blink 1s linear infinite;\">\(text)</span><style>@keyframes blink { 50% { opacity: 0; } }</style>"
    }
}

/// Marquee shortcode (another GeoCities classic!)
struct MarqueeShortcode: Shortcode {
    let name = "marquee"

    func render(params: [String: String], content: String?) -> String {
        let text = (content ?? "").htmlEscaped
        let direction =
            ["left", "right", "up", "down"].contains(params["direction"])
            ? params["direction"]! : "left"
        let speed =
            ["fast", "slow", "normal"].contains(params["speed"]) ? params["speed"]! : "normal"

        let scrollAmount = speed == "fast" ? "20" : speed == "slow" ? "5" : "10"

        return
            "<marquee direction=\"\(direction)\" scrollamount=\"\(scrollAmount)\">\(text)</marquee>"
    }
}

/// YouTube embed shortcode
struct YouTubeShortcode: Shortcode {
    let name = "youtube"

    func render(params: [String: String], content: String?) -> String {
        guard let videoId = params["id"] else {
            return "<!-- YouTube shortcode: missing id parameter -->"
        }

        // Sanitize videoId - YouTube IDs are alphanumeric with dashes and underscores
        let sanitizedVideoId = videoId.htmlEscaped.filter {
            $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_"
        }

        let width = (params["width"] ?? "560").htmlEscaped
        let height = (params["height"] ?? "315").htmlEscaped

        return
            "<div class=\"video-container\" style=\"position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden;\"><iframe style=\"position: absolute; top: 0; left: 0; width: 100%; height: 100%;\" width=\"\(width)\" height=\"\(height)\" src=\"https://www.youtube.com/embed/\(sanitizedVideoId)\" frameborder=\"0\" allow=\"accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture\" allowfullscreen></iframe></div>"
    }
}

/// Image with caption shortcode
struct ImageShortcode: Shortcode {
    let name = "image"

    func render(params: [String: String], content: String?) -> String {
        guard let src = params["src"] else {
            return "<!-- Image shortcode: missing src parameter -->"
        }

        let escapedSrc = src.htmlEscaped
        let escapedAlt = (params["alt"] ?? "").htmlEscaped
        let caption = params["caption"] ?? content
        let width = params["width"]
        let align =
            ["left", "center", "right"].contains(params["align"]) ? params["align"]! : "center"

        var html = "<figure style=\"text-align: \(align);\">"

        if let width = width {
            let escapedWidth = width.htmlEscaped
            html += "<img src=\"\(escapedSrc)\" alt=\"\(escapedAlt)\" width=\"\(escapedWidth)\" />"
        } else {
            html += "<img src=\"\(escapedSrc)\" alt=\"\(escapedAlt)\" />"
        }

        if let caption = caption, !caption.isEmpty {
            html += "<figcaption>\(caption.htmlEscaped)</figcaption>"
        }

        html += "</figure>"
        return html
    }
}

/// Alert/callout box shortcode
struct AlertShortcode: Shortcode {
    let name = "alert"

    func render(params: [String: String], content: String?) -> String {
        // Validate and sanitize type parameter
        let validTypes = ["info", "warning", "error", "danger", "success"]
        let type = validTypes.contains(params["type"] ?? "") ? params["type"]! : "info"
        let title = params["title"]
        let message = (content ?? "").htmlEscaped

        let (bgColor, textColor, icon) = styleFor(type: type)

        var html =
            "<div class=\"alert alert-\(type)\" style=\"padding: 1rem; margin: 1rem 0; background: \(bgColor); color: \(textColor); border-left: 4px solid \(textColor); border-radius: 4px;\">"

        if let title = title, !title.isEmpty {
            html +=
                "<strong style=\"display: block; margin-bottom: 0.5rem;\">\(icon) \(title.htmlEscaped)</strong>"
        }

        html += message
        html += "</div>"

        return html
    }

    private func styleFor(type: String) -> (bg: String, text: String, icon: String) {
        switch type {
        case "warning":
            return ("#fff3cd", "#856404", "⚠️")
        case "error", "danger":
            return ("#f8d7da", "#721c24", "❌")
        case "success":
            return ("#d4edda", "#155724", "✅")
        default:  // info
            return ("#d1ecf1", "#0c5460", "ℹ️")
        }
    }
}

/// Visit counter shortcode (GeoCities nostalgia!)
struct CounterShortcode: Shortcode {
    let name = "counter"

    func render(params: [String: String], content: String?) -> String {
        let style = params["style"] ?? "digital"
        let number = Int.random(in: 1000...99999)  // Random counter for now

        if style == "digital" {
            return
                "<div class=\"visitor-counter\" style=\"font-family: 'Courier New', monospace; background: #000; color: #0f0; padding: 0.5rem; display: inline-block; border: 2px solid #0f0;\">VISITORS: \(String(format: "%05d", number))</div>"
        } else {
            return
                "<span class=\"visitor-counter\" style=\"font-weight: bold;\">👁️ \(number) visitors</span>"
        }
    }
}

/// Rainbow text shortcode (maximum GeoCities!)
struct RainbowTextShortcode: Shortcode {
    let name = "rainbow"

    func render(params: [String: String], content: String?) -> String {
        let text = content ?? ""
        let colors = ["#ff0000", "#ff7f00", "#ffff00", "#00ff00", "#0000ff", "#4b0082", "#9400d3"]

        var html = ""
        for (index, char) in text.enumerated() {
            let color = colors[index % colors.count]
            html += "<span style=\"color: \(color);\">\(char)</span>"
        }

        return html
    }
}
