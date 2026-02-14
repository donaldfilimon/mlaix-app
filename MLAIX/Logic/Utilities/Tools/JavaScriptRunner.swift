//
//  JavaScriptRunner.swift
//  MLAI
//
//  Created by John Bean on 3/4/25.
//

import Foundation
import JavaScriptCore

/// A single console message (log, warn, or error).
public struct ConsoleEntry: Sendable {
	public enum Level: String, Sendable {
		case log, warn, error
	}
	public let level: Level
	public let message: String
}

/// Result of JavaScript execution with optional console output.
public struct JavaScriptExecutionResult: Sendable {
	public let result: String
	public let consoleOutput: [ConsoleEntry]
}

/// A class to execute JavaScript
public class JavaScriptRunner {

	/// Execute JavaScript and return result with console output for script testing.
	public static func executeWithConsoleOutput(_ code: String) throws -> JavaScriptExecutionResult {
		guard let context: JSContext = JSContext() else {
			throw JSError.failedToInitContext
		}
		var logEntries: [ConsoleEntry] = []
		let makeLogger: (ConsoleEntry.Level) -> @convention(block) (JSValue) -> Void = { level in
			{ value in
				logEntries.append(ConsoleEntry(level: level, message: value.toString() ?? "\(value)"))
			}
		}
		if let console = context.objectForKeyedSubscript("console") {
			console.setObject(makeLogger(.log), forKeyedSubscript: "log")
			console.setObject(makeLogger(.warn), forKeyedSubscript: "warn")
			console.setObject(makeLogger(.error), forKeyedSubscript: "error")
		}
		var exceptionMsg: String?
		context.exceptionHandler = { _, exception in
			exceptionMsg = exception?.toString()
		}
		let result = context.evaluateScript(code)
		if let msg = exceptionMsg {
			throw JSError.exception(error: msg)
		}
		guard let result else {
			throw JSError.executionFailed
		}
		let resultStr = result.toString() ?? ""
		let finalResult: String
		if !resultStr.isEmpty && resultStr != "undefined" {
			finalResult = resultStr
		} else if !logEntries.isEmpty {
			finalResult = logEntries.map(\.message).joined(separator: "\n")
		} else if resultStr == "undefined" {
			throw JSError.exception(error: "undefined")
		} else {
			throw JSError.couldNotObtainResult
		}
		return JavaScriptExecutionResult(result: finalResult, consoleOutput: logEntries)
	}

	/// Function to execute JavaScript and return the result (JavaScriptCore).
	/// - Parameter code: The JavaScript code to be run
	/// - Returns: The result produced from the JavaScript code
	public static func executeJavaScript(
		_ code: String
	) throws -> String {
		try executeWithConsoleOutput(code).result
	}

	/// Allowed character set for safe expression evaluation (arithmetic only).
	private static let expressionAllowedCharacterSet = CharacterSet(charactersIn: "0123456789.+-*/%() \t\n")

	/// Evaluates a single arithmetic expression via JavaScriptCore and returns the result.
	/// Only numbers and operators (+, -, *, /, %, parentheses, spaces) are allowed for safety.
	/// For full JavaScript use `run_javascript` / `executeJavaScript` instead.
	public static func evaluateExpression(_ expression: String) throws -> String {
		let trimmed = expression.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !trimmed.isEmpty else {
			throw JSError.exception(error: "Empty expression")
		}
		guard trimmed.unicodeScalars.allSatisfy({ expressionAllowedCharacterSet.contains($0) }) else {
			throw JSError.exception(error: "Expression may only contain numbers and + - * / % ( )")
		}
		guard let context = JSContext() else {
			throw JSError.failedToInitContext
		}
		var exceptionMsg: String?
		context.exceptionHandler = { _, exception in
			exceptionMsg = exception?.toString()
		}
		// Wrap in parentheses so the parser treats it as an expression
		let wrapped = "(\(trimmed))"
		guard let result = context.evaluateScript(wrapped) else {
			throw JSError.executionFailed
		}
		if let msg = exceptionMsg {
			throw JSError.exception(error: msg)
		}
		if result.isUndefined {
			throw JSError.couldNotObtainResult
		}
		return result.toString() ?? "\(result)"
	}

	/// Enum for possible errors during JavaScript execution
    public enum JSError: LocalizedError {
        
		case failedToInitContext
		case exception(error: String)
		case executionFailed
		case couldNotObtainResult
        
        public var errorDescription: String? {
            switch self {
                case .failedToInitContext:
                    return "Failed to initialize `JSContext` object"
                case .exception(let error):
                    return "JavaScript execution failed: \(error)"
                case .executionFailed:
                    return "JavaScript execution failed"
                case .couldNotObtainResult:
                    return "JavaScript execution did not return a result"
            }
        }
	}
	
}
