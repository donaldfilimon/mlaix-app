//
//  JavaScriptRunnerTests.swift
//  MLAITests
//
//  Tests for JavaScriptRunner, executeWithConsoleOutput, and console.log/warn/error.
//

import Foundation
import Testing

@testable import MLAIX

struct JavaScriptRunnerTests {

    @Test func executeWithConsoleOutput_returnsResultAndLogs() throws {
        let code = """
        console.log("hello");
        console.log("world");
        42
        """
        let result = try JavaScriptRunner.executeWithConsoleOutput(code)
        #expect(result.result == "42")
        #expect(result.consoleOutput.count == 2)
        #expect(result.consoleOutput[0].level == .log)
        #expect(result.consoleOutput[0].message == "hello")
        #expect(result.consoleOutput[1].message == "world")
    }

    @Test func executeWithConsoleOutput_capturesWarnAndError() throws {
        let code = """
        console.log("info");
        console.warn("warning");
        console.error("error");
        "done"
        """
        let result = try JavaScriptRunner.executeWithConsoleOutput(code)
        #expect(result.result == "done")
        #expect(result.consoleOutput.count == 3)
        #expect(result.consoleOutput[0].level == .log && result.consoleOutput[0].message == "info")
        #expect(result.consoleOutput[1].level == .warn && result.consoleOutput[1].message == "warning")
        #expect(result.consoleOutput[2].level == .error && result.consoleOutput[2].message == "error")
    }

    @Test func executeWithConsoleOutput_usesLogsWhenNoReturnValue() throws {
        let code = """
        console.log("only logs");
        console.log("no return");
        """
        let result = try JavaScriptRunner.executeWithConsoleOutput(code)
        #expect(result.result == "only logs\nno return")
        #expect(result.consoleOutput.count == 2)
    }

    @Test func executeJavaScript_returnsResultOnly() throws {
        let code = "1 + 2"
        let result = try JavaScriptRunner.executeJavaScript(code)
        #expect(result == "3")
    }

    @Test func executeJavaScript_throwsOnException() {
        #expect(throws: JavaScriptRunner.JSError.self) {
            _ = try JavaScriptRunner.executeJavaScript("throw new Error('oops')")
        }
    }
}
