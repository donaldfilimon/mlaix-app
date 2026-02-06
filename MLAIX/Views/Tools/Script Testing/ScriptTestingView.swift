//
//  ScriptTestingView.swift
//  MLAI
//
//  Built-in JavaScript (JavaScriptCore) and WebView for script testing with progress visibility.
//

import SwiftUI
import WebViewKit

struct ScriptTestingView: View {

    @State private var code: String = """
    // JavaScript (JavaScriptCore) - try it!
    console.log("Hello from JavaScriptCore");
    const sum = [1, 2, 3, 4, 5].reduce((a, b) => a + b, 0);
    console.log("Sum:", sum);
    sum
    """
    @State private var output: String = ""
    @State private var consoleOutput: [ConsoleEntry] = []
    @State private var isRunning: Bool = false
    @State private var errorMessage: String?
    @State private var selectedTab: OutputTab = .output
    @State private var htmlPreviewUrl: URL?

    private enum OutputTab: String, CaseIterable, Hashable {
        case output = "Output"
        case console = "Console"
        case webview = "WebView"
    }

    private enum ScriptSnippet: String, CaseIterable {
        case hello = "Hello"
        case consoleLevels = "Console (log/warn/error)"
        case arrayReduce = "Array reduce"
        case htmlOutput = "HTML output (WebView)"
        case jsonParse = "JSON parse"

        var title: String { rawValue }

        var code: String {
            switch self {
            case .hello:
                return """
                console.log("Hello from JavaScriptCore");
                const sum = [1, 2, 3, 4, 5].reduce((a, b) => a + b, 0);
                console.log("Sum:", sum);
                sum
                """
            case .consoleLevels:
                return """
                console.log("Info message");
                console.warn("Warning message");
                console.error("Error message");
                "Check Console tab for styled output"
                """
            case .arrayReduce:
                return """
                const nums = [10, 20, 30, 40];
                const total = nums.reduce((a, b) => a + b, 0);
                const avg = total / nums.length;
                JSON.stringify({ total, avg, count: nums.length })
                """
            case .htmlOutput:
                return """
                const items = ["Apple", "Banana", "Cherry"];
                const list = items.map(i => `<li>${i}</li>`).join("");
                `<div><h3>Fruits</h3><ul>${list}</ul></div>`
                """
            case .jsonParse:
                return """
                const json = '{"name":"MLAI","version":1}';
                const obj = JSON.parse(json);
                console.log("Parsed:", obj);
                obj.name + " v" + obj.version
                """
            }
        }
    }

    var body: some View {
        HSplitView {
            codeEditor
                .frame(minWidth: 280)
            Divider()
            outputPanel
                .frame(minWidth: 280)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Menu {
                    ForEach(ScriptSnippet.allCases, id: \.self) { snippet in
                        Button(snippet.title) {
                            code = snippet.code
                        }
                    }
                } label: {
                    Label("Examples", systemImage: "doc.text")
                }
                .help("Load example snippets")
                Button {
                    runScript()
                } label: {
                    Label("Run", systemImage: "play.fill")
                }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(isRunning || code.trimmingCharacters(in: .whitespaces).isEmpty)
                .help("Run script (⌘↵)")
                if isRunning {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
        }
    }

    private var codeEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("JavaScript (JavaScriptCore)")
                .font(.headline)
            TextEditor(text: $code)
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .background(Color(nsColor: .textBackgroundColor))
        }
        .padding()
    }

    private var outputPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Output")
                    .font(.headline)
                Picker("", selection: $selectedTab) {
                    ForEach(OutputTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            Group {
                switch selectedTab {
                case .output:
                    outputContent
                case .console:
                    consoleContent
                case .webview:
                    webviewContent
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding()
    }

    private var outputContent: some View {
        ScrollView {
            Text(output.isEmpty ? "Run a script to see output." : output)
                .font(.system(.body, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
                .padding()
        }
        .background(Color(nsColor: .textBackgroundColor))
    }

    private var consoleContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(consoleOutput.enumerated()), id: \.offset) { _, entry in
                    HStack(alignment: .top, spacing: 6) {
                        Text(entry.level.rawValue)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(levelColor(entry.level))
                            .frame(width: 36, alignment: .leading)
                        Text(entry.message)
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                }
                if consoleOutput.isEmpty {
                    Text("console.log / warn / error output appears here.")
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor))
    }

    private func levelColor(_ level: ConsoleEntry.Level) -> Color {
        switch level {
        case .log: return .secondary
        case .warn: return .orange
        case .error: return .red
        }
    }

    private var webviewContent: some View {
        Group {
            if let url = htmlPreviewUrl {
                WebView(url: url)
            } else {
                VStack {
                    Text("WebView preview")
                        .foregroundStyle(.secondary)
                    Text("Run a script that returns HTML to see it here.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    @MainActor
    private func runScript() {
        output = ""
        consoleOutput = []
        errorMessage = nil
        htmlPreviewUrl = nil
        isRunning = true

        Task { @MainActor in
            do {
                let result = try JavaScriptRunner.executeWithConsoleOutput(code)
                output = result.result
                consoleOutput = result.consoleOutput
                if isLikelyHTML(result.result) {
                    htmlPreviewUrl = writeHTMLToTempFile(result.result)
                }
            } catch {
                output = "Error: \(error.localizedDescription)"
                errorMessage = error.localizedDescription
            }
            isRunning = false
        }
    }

    private func isLikelyHTML(_ str: String) -> Bool {
        let trimmed = str.trimmingCharacters(in: .whitespaces)
        return trimmed.hasPrefix("<") && (trimmed.contains("<html") || trimmed.contains("<div") || trimmed.contains("<body"))
    }

    private func writeHTMLToTempFile(_ html: String) -> URL? {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("MLAI-ScriptTesting", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("preview.html")
        let fullHTML = """
        <!DOCTYPE html>
        <html><head><meta charset="utf-8"></head>
        <body>\(html)</body>
        </html>
        """
        try? fullHTML.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}

#Preview {
    ScriptTestingView()
        .frame(width: 700, height: 450)
}
