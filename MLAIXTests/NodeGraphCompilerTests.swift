//
//  NodeGraphCompilerTests.swift
//  MLAIXTests
//
//  Tests for NodeGraphCompiler: graph → JavaScript compilation and errors.
//

import Foundation
import Testing
@testable import MLAIX

struct NodeGraphCompilerTests {

    @Test func compileRequiresStartNode() throws {
        var graph = NodeGraph()
        graph.addNode(ScriptNode(kind: .number, position: .zero, numberValue: 1))
        #expect(throws: NodeGraphCompiler.CompileError.self) {
            try NodeGraphCompiler.compile(graph)
        }
    }

    @Test func compileDefaultGraphProducesNumberResult() throws {
        var graph = NodeGraph()
        let start = ScriptNode(kind: .start, position: .zero)
        let num = ScriptNode(kind: .number, position: .zero, numberValue: 42)
        let out = ScriptNode(kind: .output, position: .zero)
        graph.addNode(start)
        graph.addNode(num)
        graph.addNode(out)
        graph.addConnection(ScriptConnection(fromNodeId: start.id, fromSlot: "out", toNodeId: num.id, toSlot: "a"))
        graph.addConnection(ScriptConnection(fromNodeId: num.id, fromSlot: "out", toNodeId: out.id, toSlot: "value"))
        let js = try NodeGraphCompiler.compile(graph)
        #expect(js.contains("const n_") == true)
        #expect(js.contains("42") == true)
        let result = try JavaScriptRunner.executeWithConsoleOutput(js)
        #expect(result.result == "42")
    }

    @Test func compileAddNodeProducesSum() throws {
        var graph = NodeGraph()
        let start = ScriptNode(kind: .start, position: .zero)
        let a = ScriptNode(kind: .number, position: .zero, numberValue: 10)
        let b = ScriptNode(kind: .number, position: .zero, numberValue: 32)
        let add = ScriptNode(kind: .add, position: .zero)
        let out = ScriptNode(kind: .output, position: .zero)
        graph.addNode(start)
        graph.addNode(a)
        graph.addNode(b)
        graph.addNode(add)
        graph.addNode(out)
        graph.addConnection(ScriptConnection(fromNodeId: start.id, fromSlot: "out", toNodeId: a.id, toSlot: "a"))
        graph.addConnection(ScriptConnection(fromNodeId: start.id, fromSlot: "out", toNodeId: b.id, toSlot: "a"))
        graph.addConnection(ScriptConnection(fromNodeId: a.id, fromSlot: "out", toNodeId: add.id, toSlot: "a"))
        graph.addConnection(ScriptConnection(fromNodeId: b.id, fromSlot: "out", toNodeId: add.id, toSlot: "b"))
        graph.addConnection(ScriptConnection(fromNodeId: add.id, fromSlot: "out", toNodeId: out.id, toSlot: "value"))
        let js = try NodeGraphCompiler.compile(graph)
        let result = try JavaScriptRunner.executeWithConsoleOutput(js)
        #expect(result.result == "42")
    }

    @Test func compileStringNodeEscapesQuotes() throws {
        var graph = NodeGraph()
        let start = ScriptNode(kind: .start, position: .zero)
        let str = ScriptNode(kind: .string, position: .zero, stringValue: "hello \"world\"")
        let out = ScriptNode(kind: .output, position: .zero)
        graph.addNode(start)
        graph.addNode(str)
        graph.addNode(out)
        graph.addConnection(ScriptConnection(fromNodeId: start.id, fromSlot: "out", toNodeId: str.id, toSlot: "a"))
        graph.addConnection(ScriptConnection(fromNodeId: str.id, fromSlot: "out", toNodeId: out.id, toSlot: "value"))
        let js = try NodeGraphCompiler.compile(graph)
        #expect(js.contains("\\\"") == true)
        let result = try JavaScriptRunner.executeWithConsoleOutput(js)
        #expect(result.result == "hello \"world\"")
    }

    @Test func compileMissingInputThrows() throws {
        var graph = NodeGraph()
        let start = ScriptNode(kind: .start, position: .zero)
        let add = ScriptNode(kind: .add, position: .zero)
        let out = ScriptNode(kind: .output, position: .zero)
        graph.addNode(start)
        graph.addNode(add)
        graph.addNode(out)
        graph.addConnection(ScriptConnection(fromNodeId: start.id, fromSlot: "out", toNodeId: add.id, toSlot: "a"))
        graph.addConnection(ScriptConnection(fromNodeId: add.id, fromSlot: "out", toNodeId: out.id, toSlot: "value"))
        #expect(throws: NodeGraphCompiler.CompileError.self) {
            try NodeGraphCompiler.compile(graph)
        }
    }

    @Test func compileCyclicGraphThrows() throws {
        // Create A → B → A cycle: start connects to A, A connects to B, B connects back to A
        var graph = NodeGraph()
        let start = ScriptNode(kind: .start, position: .zero)
        let a = ScriptNode(kind: .number, position: .zero, numberValue: 1)
        let b = ScriptNode(kind: .number, position: .zero, numberValue: 2)
        graph.addNode(start)
        graph.addNode(a)
        graph.addNode(b)
        graph.addConnection(ScriptConnection(fromNodeId: start.id, fromSlot: "out", toNodeId: a.id, toSlot: "a"))
        graph.addConnection(ScriptConnection(fromNodeId: a.id, fromSlot: "out", toNodeId: b.id, toSlot: "a"))
        graph.addConnection(ScriptConnection(fromNodeId: b.id, fromSlot: "out", toNodeId: a.id, toSlot: "a"))
        #expect(throws: NodeGraphCompiler.CompileError.self) {
            try NodeGraphCompiler.compile(graph)
        }
    }

    @Test func compileRunJSNodeExecutes() throws {
        var graph = NodeGraph()
        let start = ScriptNode(kind: .start, position: .zero)
        var jsNode = ScriptNode(kind: .runJS, position: .zero)
        jsNode.runJSCode = "return 7 * 6;"
        let out = ScriptNode(kind: .output, position: .zero)
        graph.addNode(start)
        graph.addNode(jsNode)
        graph.addNode(out)
        graph.addConnection(ScriptConnection(fromNodeId: start.id, fromSlot: "out", toNodeId: jsNode.id, toSlot: "a"))
        graph.addConnection(ScriptConnection(fromNodeId: jsNode.id, fromSlot: "out", toNodeId: out.id, toSlot: "value"))
        let js = try NodeGraphCompiler.compile(graph)
        #expect(js.contains("(function()") == true, "RunJS node should wrap code in IIFE")
        let result = try JavaScriptRunner.executeWithConsoleOutput(js)
        #expect(result.result == "42")
    }

    @Test func compileLogNodeProducesConsoleOutput() throws {
        var graph = NodeGraph()
        let start = ScriptNode(kind: .start, position: .zero)
        let num = ScriptNode(kind: .number, position: .zero, numberValue: 99)
        let logNode = ScriptNode(kind: .log, position: .zero)
        let out = ScriptNode(kind: .output, position: .zero)
        graph.addNode(start)
        graph.addNode(num)
        graph.addNode(logNode)
        graph.addNode(out)
        graph.addConnection(ScriptConnection(fromNodeId: start.id, fromSlot: "out", toNodeId: num.id, toSlot: "a"))
        graph.addConnection(ScriptConnection(fromNodeId: num.id, fromSlot: "out", toNodeId: logNode.id, toSlot: "value"))
        graph.addConnection(ScriptConnection(fromNodeId: logNode.id, fromSlot: "out", toNodeId: out.id, toSlot: "value"))
        let js = try NodeGraphCompiler.compile(graph)
        #expect(js.contains("console.log") == true, "Log node should emit console.log")
        let result = try JavaScriptRunner.executeWithConsoleOutput(js)
        #expect(result.consoleOutput.count == 1, "Should produce one console entry")
        #expect(result.consoleOutput.first?.message == "99")
    }

    @Test func compileDisconnectedNodesSkipped() throws {
        // Disconnected node (not reachable from start) should not appear in output
        var graph = NodeGraph()
        let start = ScriptNode(kind: .start, position: .zero)
        let connected = ScriptNode(kind: .number, position: .zero, numberValue: 10)
        let disconnected = ScriptNode(kind: .number, position: .zero, numberValue: 999)
        let out = ScriptNode(kind: .output, position: .zero)
        graph.addNode(start)
        graph.addNode(connected)
        graph.addNode(disconnected)
        graph.addNode(out)
        graph.addConnection(ScriptConnection(fromNodeId: start.id, fromSlot: "out", toNodeId: connected.id, toSlot: "a"))
        graph.addConnection(ScriptConnection(fromNodeId: connected.id, fromSlot: "out", toNodeId: out.id, toSlot: "value"))
        let js = try NodeGraphCompiler.compile(graph)
        #expect(js.contains("999") == false, "Disconnected node value should not appear in JS")
        #expect(js.contains("10") == true, "Connected node value should appear")
    }

    @Test func compileMultiplePathsConverge() throws {
        // Two number nodes feed into an add node: both paths converge
        var graph = NodeGraph()
        let start = ScriptNode(kind: .start, position: .zero)
        let left = ScriptNode(kind: .number, position: .zero, numberValue: 100)
        let right = ScriptNode(kind: .number, position: .zero, numberValue: 200)
        let add = ScriptNode(kind: .add, position: .zero)
        let out = ScriptNode(kind: .output, position: .zero)
        graph.addNode(start)
        graph.addNode(left)
        graph.addNode(right)
        graph.addNode(add)
        graph.addNode(out)
        // Start fans out to both numbers
        graph.addConnection(ScriptConnection(fromNodeId: start.id, fromSlot: "out", toNodeId: left.id, toSlot: "a"))
        graph.addConnection(ScriptConnection(fromNodeId: start.id, fromSlot: "out", toNodeId: right.id, toSlot: "a"))
        // Both feed into add
        graph.addConnection(ScriptConnection(fromNodeId: left.id, fromSlot: "out", toNodeId: add.id, toSlot: "a"))
        graph.addConnection(ScriptConnection(fromNodeId: right.id, fromSlot: "out", toNodeId: add.id, toSlot: "b"))
        // Add feeds into output
        graph.addConnection(ScriptConnection(fromNodeId: add.id, fromSlot: "out", toNodeId: out.id, toSlot: "value"))
        let js = try NodeGraphCompiler.compile(graph)
        let result = try JavaScriptRunner.executeWithConsoleOutput(js)
        #expect(result.result == "300", "100 + 200 should equal 300")
    }

    @Test func compileErrorDescriptions() throws {
        // Verify all CompileError cases produce non-empty descriptions
        let testId = UUID()
        let errors: [NodeGraphCompiler.CompileError] = [
            .noStartNode,
            .missingInput(nodeId: testId, slot: "value"),
            .unknownNode(testId),
            .cyclicGraph(nodeId: testId),
        ]
        for error in errors {
            let desc = error.errorDescription ?? ""
            #expect(!desc.isEmpty, "Error \(error) should have a description")
        }
    }
}
