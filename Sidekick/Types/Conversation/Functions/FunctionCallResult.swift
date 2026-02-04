//
//  FunctionCallResult.swift
//  Sidekick
//
//  Created by John Bean on 5/5/25.
//

import Foundation

/// Represents the result of a function call during inference.
/// Conforms to `Sendable` for safe cross-actor/thread usage.
public struct FunctionCallResult: Codable, Sendable, Hashable {

    /// The function call that was made (e.g., "searchWeb(query: \"weather\")")
    public let call: String

    /// The result or error message from the function call
    public let result: String?

    /// Whether this represents a successful result or an error
    public let type: ResultType

    /// Creates a new function call result
    /// - Parameters:
    ///   - call: The function call that was made
    ///   - result: The result or error message
    ///   - type: Whether this is a success or error
    public init(call: String, result: String?, type: ResultType) {
        self.call = call
        self.result = result
        self.type = type
    }

    /// Creates a successful result
    public static func success(call: String, result: String?) -> FunctionCallResult {
        FunctionCallResult(call: call, result: result, type: .result)
    }

    /// Creates an error result
    public static func failure(call: String, error: String) -> FunctionCallResult {
        FunctionCallResult(call: call, result: error, type: .error)
    }

    /// The type of function call result
    public enum ResultType: String, Codable, CaseIterable, Sendable {
        case result
        case error
    }

    /// A formatted description of the result for display in the conversation
    public var description: String {
        switch self.type {
            case .result:
                return """
Below is the result produced by the tool call: `\(self.call)`.

```tool_call_result
\(self.result ?? "null")
```
"""
            case .error:
                return """
The function call `\(self.call)` failed, producing the error below.

```tool_call_error
\(self.result ?? "null")
```
"""
        }
    }

}

// MARK: - Legacy Type Alias

/// Type alias for backward compatibility with code using the old `Type` name
public typealias FunctionCallResultType = FunctionCallResult.ResultType
