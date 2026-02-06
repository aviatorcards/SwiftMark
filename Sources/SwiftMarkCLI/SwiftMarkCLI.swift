import Foundation
import ArgumentParser
import SwiftMark

@main
struct SwiftMarkCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "swiftmark",
        abstract: "A tool to process markdown files with frontmatter and shortcodes.",
        version: "1.0.0"
    )

    @Argument(help: "The markdown file or directory to process.")
    var path: String

    @Option(name: .shortAndLong, help: "Output directory for rendered HTML.")
    var output: String?

    @Flag(name: .shortAndLong, help: "Enable strict CommonMark mode.")
    var strict = false

    @Flag(help: "Disable shortcode processing.")
    var noShortcodes = false

    @Flag(help: "Disable syntax highlighting.")
    var noHighlight = false

    mutating func run() async throws {
        let options = MarkdownOptions(
            strictMode: strict,
            enableShortcodes: !noShortcodes,
            syntaxHighlighting: !noHighlight
        )
        let processor = MarkdownProcessor(options: options)
        let url = URL(fileURLWithPath: path)

        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) {
            if isDir.boolValue {
                try await processDirectory(url, processor: processor)
            } else {
                try processFile(url, processor: processor)
            }
        } else {
            print("Error: Path does not exist: \(path)")
            throw ExitCode.failure
        }
    }

    private func processFile(_ file: URL, processor: MarkdownProcessor) throws {
        print("Processing \(file.lastPathComponent)...")
        let page = try processor.process(file: file, relativeTo: file.deletingLastPathComponent())
        
        if let outputDir = output {
            let outputURL = URL(fileURLWithPath: outputDir)
                .appendingPathComponent(file.deletingPathExtension().lastPathComponent)
                .appendingPathExtension("html")
            
            try? FileManager.default.createDirectory(at: URL(fileURLWithPath: outputDir), withIntermediateDirectories: true)
            try page.content.write(to: outputURL, atomically: true, encoding: .utf8)
            print("Saved to \(outputURL.path)")
        } else {
            print("--- HTML Output ---")
            print(page.content)
        }
    }

    private func processDirectory(_ dir: URL, processor: MarkdownProcessor) async throws {
        print("Processing directory \(dir.path)...")
        let fileManager = FileManager.default
        let resourceKeys: [URLResourceKey] = [.isRegularFileKey]
        
        guard let enumerator = fileManager.enumerator(
            at: dir,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return
        }

        var markdownFiles: [URL] = []
        while let fileURL = enumerator.nextObject() as? URL {
            if fileURL.pathExtension == "md" {
                markdownFiles.append(fileURL)
            }
        }

        print("Found \(markdownFiles.count) markdown files.")
        
        let pages = try await processor.process(files: markdownFiles, relativeTo: dir)
        
        if let outputDir = output {
            let outputURL = URL(fileURLWithPath: outputDir)
            try? fileManager.createDirectory(at: outputURL, withIntermediateDirectories: true)
            
            for page in pages {
                let fileOutputURL = outputURL.appendingPathComponent(page.path)
                    .deletingPathExtension()
                    .appendingPathExtension("html")
                
                try? fileManager.createDirectory(at: fileOutputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                try page.content.write(to: fileOutputURL, atomically: true, encoding: .utf8)
            }
            print("Processed \(pages.count) files to \(outputDir)")
        } else {
            for page in pages {
                print("Processed: \(page.path)")
            }
        }
    }
}
