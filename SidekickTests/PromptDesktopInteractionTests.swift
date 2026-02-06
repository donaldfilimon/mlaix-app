//
//  PromptDesktopInteractionTests.swift
//  MLAITests
//
//  Real desktop interaction smoke tests executed via SwiftPM.
//

import Foundation
import AppKit
import ApplicationServices
import Testing

struct PromptDesktopInteractionTests {

    private struct ShellResult {
        let status: Int32
        let output: String
    }

    private enum ShellError: Error {
        case failed(command: String, status: Int32, output: String)
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
        guard ProcessInfo.processInfo.environment["MLAI_UI_INTERACTION_TESTS"] == "1" else {
            return
        }

        let startEpoch = Int(Date().timeIntervalSince1970)
        _ = try requireShellSuccess("pkill -f '.build/arm64-apple-macosx/debug/MLAI' || true")

        let binaryPath = try requireShellSuccess("pwd").trimmingCharacters(in: .whitespacesAndNewlines)
            + "/.build/arm64-apple-macosx/debug/MLAI"
        let launchOutput = try requireShellSuccess(
            "'\(binaryPath)' >/tmp/mlai_ui_interaction_test.log 2>&1 & echo $!",
            timeout: 20
        )
        let pidString = launchOutput.trimmingCharacters(in: .whitespacesAndNewlines)
        #expect(!pidString.isEmpty)
        guard let pid = Int32(pidString) else {
            throw ShellError.failed(command: "parse pid", status: 1, output: pidString)
        }

        defer {
            _ = try? runShell("kill \(pidString) || true")
            _ = try? runShell("pkill -f '.build/arm64-apple-macosx/debug/MLAI' || true")
        }

        _ = try requireShellSuccess(
            "for i in {1..120}; do kill -0 \(pidString) 2>/dev/null && pgrep -f '.build/arm64-apple-macosx/debug/MLAI' >/dev/null && exit 0; sleep 0.5; done; exit 1",
            timeout: 70
        )

        NSRunningApplication(processIdentifier: pid)?.activate()
        Thread.sleep(forTimeInterval: 0.6)

        let appElement = AXUIElementCreateApplication(pid)
        var editorElement: AXUIElement?
        for _ in 0..<80 {
            editorElement = findEditableTextElement(appElement)
            if editorElement != nil {
                break
            }
            Thread.sleep(forTimeInterval: 0.1)
        }
        #expect(editorElement != nil)
        guard let editorElement else {
            throw ShellError.failed(command: "find AX text element", status: 1, output: "not found")
        }

        let setFirst = AXUIElementSetAttributeValue(
            editorElement,
            kAXValueAttribute as CFString,
            "ABCDE" as CFTypeRef
        )
        #expect(setFirst == .success)

        let firstValue: String? = copyAXAttribute(editorElement, kAXValueAttribute as CFString)
        #expect(firstValue == "ABCDE")

        let setSecond = AXUIElementSetAttributeValue(
            editorElement,
            kAXValueAttribute as CFString,
            "ABCXDE" as CFTypeRef
        )
        #expect(setSecond == .success)

        let secondValue: String? = copyAXAttribute(editorElement, kAXValueAttribute as CFString)
        #expect(secondValue == "ABCXDE")

        let crashCheck = try requireShellSuccess("""
        python3 - <<'PY'
        import pathlib
        start = \(startEpoch)
        p = pathlib.Path.home() / 'Library/Logs/DiagnosticReports'
        hits = sorted([x.name for x in p.glob('MLAI-*.ips') if x.stat().st_mtime >= start])
        print('\\n'.join(hits))
        PY
        """)
        #expect(crashCheck.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
}
