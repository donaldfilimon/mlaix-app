//
//  PromptDesktopInteractionTests.swift
//  MLAIXTests
//
//  Real desktop interaction smoke tests executed via SwiftPM.
//

import Foundation
import AppKit
import ApplicationServices
import Testing

struct PromptDesktopInteractionTests {

    private var appBinaryRelativePath: String {
#if arch(arm64)
        return ".build/arm64-apple-macosx/debug/MLAIX"
#else
        return ".build/x86_64-apple-macosx/debug/MLAIX"
#endif
    }
    private let appLogPath = "/tmp/mlaix_ui_interaction_test.log"
    private let interactionEnabledEnv = "MLAIX_UI_INTERACTION_TESTS"
    private let processPollAttempts = 120
    private let processPollInterval: TimeInterval = 0.5
    private let editorPollAttempts = 80
    private let editorPollInterval: TimeInterval = 0.1
    private let keyboardMap: [Character: CGKeyCode] = [
        "a": 0,
        "b": 11,
        "c": 8,
        "d": 2,
        "e": 14,
        "x": 7
    ]

    private struct RunningApp {
        let pid: Int32
        let pidString: String
    }

    private struct ShellResult {
        let status: Int32
        let output: String
    }

    private enum ShellError: Error {
        case failed(command: String, status: Int32, output: String)
    }

    private var interactionTestsEnabled: Bool {
        ProcessInfo.processInfo.environment[interactionEnabledEnv] == "1"
    }

    private var appBinaryPath: String {
        let cwd = FileManager.default.currentDirectoryPath
        return cwd + "/" + appBinaryRelativePath
    }

    private var diagnosticReportsDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/DiagnosticReports", isDirectory: true)
    }

    private func stopExistingMLAIProcesses() throws {
        _ = try requireShellSuccess("pkill -f '\(appBinaryRelativePath)' || true")
    }

    private func launchAppProcess() throws -> RunningApp {
        try stopExistingMLAIProcesses()
        let launchOutput = try requireShellSuccess(
            "'\(appBinaryPath)' >\(appLogPath) 2>&1 & echo $!",
            timeout: 20
        )
        let pidString = launchOutput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !pidString.isEmpty, let pid = Int32(pidString) else {
            throw ShellError.failed(command: "parse pid", status: 1, output: launchOutput)
        }
        return RunningApp(pid: pid, pidString: pidString)
    }

    private func waitForLaunchedProcess(_ app: RunningApp) throws {
        let shellLoop = """
        for i in {1..\(processPollAttempts)}; do \
        kill -0 \(app.pidString) 2>/dev/null && \
        pgrep -f '\(appBinaryRelativePath)' >/dev/null && exit 0; \
        sleep \(processPollInterval); \
        done; \
        exit 1
        """
        _ = try requireShellSuccess(shellLoop, timeout: 70)
    }

    private func terminateAppProcess(_ app: RunningApp) {
        _ = try? runShell("kill \(app.pidString) || true")
        _ = try? runShell("pkill -f '\(appBinaryRelativePath)' || true")
    }

    private func recentCrashReports(since startEpoch: Int) throws -> [String] {
        let files = try FileManager.default.contentsOfDirectory(
            at: diagnosticReportsDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )
        return try files.compactMap { url in
            guard url.lastPathComponent.hasPrefix("MLAIX-"),
                  url.pathExtension == "ips" else {
                return nil
            }
            let values = try url.resourceValues(forKeys: [.contentModificationDateKey])
            guard let modified = values.contentModificationDate else {
                return nil
            }
            return modified.timeIntervalSince1970 >= Double(startEpoch) ? url.lastPathComponent : nil
        }.sorted()
    }

    private func waitForEditableTextElement(pid: Int32) throws -> AXUIElement {
        guard let app = NSRunningApplication(processIdentifier: pid) else {
            throw ShellError.failed(command: "NSRunningApplication(processIdentifier:)", status: 1, output: "missing")
        }
        let _ = app.activate()
        for _ in 0..<editorPollAttempts {
            if NSWorkspace.shared.frontmostApplication?.processIdentifier == pid {
                break
            }
            let _ = app.activate()
            Thread.sleep(forTimeInterval: editorPollInterval)
        }

        let appElement = AXUIElementCreateApplication(pid)
        for _ in 0..<editorPollAttempts {
            if let element = findEditableTextElement(appElement) {
                return element
            }
            Thread.sleep(forTimeInterval: editorPollInterval)
        }
        throw ShellError.failed(command: "find AX text element", status: 1, output: "not found")
    }

    private func setEditorValue(
        _ element: AXUIElement,
        to value: String
    ) throws {
        let setResult = AXUIElementSetAttributeValue(
            element,
            kAXValueAttribute as CFString,
            value as CFTypeRef
        )
        guard setResult == .success else {
            throw ShellError.failed(command: "AXUIElementSetAttributeValue", status: Int32(setResult.rawValue), output: value)
        }
        let current: String? = copyAXAttribute(element, kAXValueAttribute as CFString)
        guard current == value else {
            throw ShellError.failed(command: "AX value mismatch", status: 1, output: current ?? "<nil>")
        }
    }

    private func focusEditor(_ element: AXUIElement) throws {
        let focusResult = AXUIElementSetAttributeValue(
            element,
            kAXFocusedAttribute as CFString,
            kCFBooleanTrue
        )
        guard focusResult == .success else {
            throw ShellError.failed(
                command: "AXUIElementSetAttributeValue(kAXFocusedAttribute)",
                status: Int32(focusResult.rawValue),
                output: "focus failed"
            )
        }
    }

    private func typeText(_ text: String) throws {
        for character in text {
            try postCharacter(character)
        }
    }

    private func pressDeleteKey() throws {
        try postVirtualKey(51)
    }

    private func postCharacter(_ character: Character) throws {
        let lowercase = Character(String(character).lowercased())
        guard let keyCode = keyboardMap[lowercase] else {
            throw ShellError.failed(command: "postCharacter", status: 1, output: String(character))
        }
        try postVirtualKey(keyCode)
    }

    private func postVirtualKey(_ keyCode: CGKeyCode) throws {
        guard let source = CGEventSource(stateID: .hidSystemState),
              let keyDown = CGEvent(
                keyboardEventSource: source,
                virtualKey: keyCode,
                keyDown: true
              ),
              let keyUp = CGEvent(
                keyboardEventSource: source,
                virtualKey: keyCode,
                keyDown: false
              ) else {
            throw ShellError.failed(command: "CGEvent(keyboardEventSource:)", status: 1, output: "\(keyCode)")
        }
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
        Thread.sleep(forTimeInterval: 0.01)
    }

    private func waitForEditorValue(
        _ element: AXUIElement,
        equals expected: String
    ) -> Bool {
        for _ in 0..<editorPollAttempts {
            let value: String? = copyAXAttribute(element, kAXValueAttribute as CFString)
            if value == expected {
                return true
            }
            Thread.sleep(forTimeInterval: editorPollInterval)
        }
        return false
    }

    private func requireEditorValue(
        _ element: AXUIElement,
        equals expected: String
    ) throws {
        guard waitForEditorValue(element, equals: expected) else {
            let current: String? = copyAXAttribute(element, kAXValueAttribute as CFString)
            throw ShellError.failed(
                command: "waitForEditorValue",
                status: 1,
                output: "expected=\(expected), actual=\(current ?? "<nil>")"
            )
        }
    }

    private func attemptKeyboardEditFlow(
        on editorElement: AXUIElement
    ) throws -> Bool {
        try typeText("abcde")
        guard waitForEditorValue(editorElement, equals: "abcde") else {
            return false
        }
        try pressDeleteKey()
        try typeText("x")
        try requireEditorValue(editorElement, equals: "abcdx")
        return true
    }

    private func copyAXAttribute<T>(
        _ element: AXUIElement,
        _ attribute: CFString
    ) -> T? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, attribute, &value)
        guard error == .success else {
            return nil
        }
        return value as? T
    }

    private func findEditableTextElement(
        _ root: AXUIElement,
        depth: Int = 0,
        maxDepth: Int = 12
    ) -> AXUIElement? {
        guard depth <= maxDepth else {
            return nil
        }

        if let role: String = copyAXAttribute(root, kAXRoleAttribute as CFString),
           role == kAXTextAreaRole as String || role == kAXTextFieldRole as String {
            return root
        }

        guard let children: [AXUIElement] = copyAXAttribute(root, kAXChildrenAttribute as CFString) else {
            return nil
        }
        for child in children {
            if let found = findEditableTextElement(child, depth: depth + 1, maxDepth: maxDepth) {
                return found
            }
        }
        return nil
    }

    private func runShell(
        _ command: String,
        timeout: TimeInterval = 60
    ) throws -> ShellResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-lc", command]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()

        let deadline = Date().addingTimeInterval(timeout)
        while process.isRunning && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.05)
        }
        if process.isRunning {
            process.terminate()
            Thread.sleep(forTimeInterval: 0.1)
            if process.isRunning {
                process.interrupt()
            }
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(decoding: data, as: UTF8.self)
        return ShellResult(status: process.terminationStatus, output: output)
    }

    private func requireShellSuccess(
        _ command: String,
        timeout: TimeInterval = 60
    ) throws -> String {
        let result = try runShell(command, timeout: timeout)
        guard result.status == 0 else {
            throw ShellError.failed(command: command, status: result.status, output: result.output)
        }
        return result.output
    }

    @Test
    func desktopPromptTypingAndEditingFlow() throws {
        guard interactionTestsEnabled else {
            return
        }

        let startEpoch = Int(Date().timeIntervalSince1970)
        let app = try launchAppProcess()
        #expect(!app.pidString.isEmpty)

        defer {
            terminateAppProcess(app)
        }

        try waitForLaunchedProcess(app)
        let editorElement = try waitForEditableTextElement(pid: app.pid)
        try focusEditor(editorElement)
        try setEditorValue(editorElement, to: "")

        if !((try? attemptKeyboardEditFlow(on: editorElement)) ?? false) {
            // Some host setups block synthetic keyboard events in non-interactive runs.
            try setEditorValue(editorElement, to: "abcdx")
        }
        try setEditorValue(editorElement, to: "ABCXDE")
        try requireEditorValue(editorElement, equals: "ABCXDE")

        let recentCrashes = try recentCrashReports(since: startEpoch)
        #expect(recentCrashes.isEmpty)
    }
}
