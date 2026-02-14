//
//  NodeEditorPersistenceTests.swift
//  MLAIXTests
//
//  Tests for NodeEditorPersistence: save/load round-trip and error handling.
//

import Foundation
import Testing
@testable import MLAIX

struct NodeEditorPersistenceTests {

    /// Creates a sample graph for testing.
    private func makeSampleGraph() -> NodeGraph {
        var graph = NodeGraph()
        let start = ScriptNode(kind: .start, position: CGPoint(x: 50, y: 100))
        let num = ScriptNode(kind: .number, position: CGPoint(x: 200, y: 100), numberValue: 42)
        let out = ScriptNode(kind: .output, position: CGPoint(x: 350, y: 100))
        graph.addNode(start)
        graph.addNode(num)
        graph.addNode(out)
        graph.addConnection(ScriptConnection(fromNodeId: start.id, fromSlot: "out", toNodeId: num.id, toSlot: "a"))
        graph.addConnection(ScriptConnection(fromNodeId: num.id, fromSlot: "out", toNodeId: out.id, toSlot: "value"))
        return graph
    }

    @Test func saveAndLoadRoundTrip() throws {
        let graph = makeSampleGraph()
        NodeEditorPersistence.save(graph)
        let loaded = NodeEditorPersistence.load()
        #expect(loaded != nil, "Loaded graph should not be nil")
        #expect(loaded == graph, "Loaded graph should equal saved graph")
    }

    @Test func loadMissingFileReturnsNil() throws {
        // Remove the file if it exists, then verify load returns nil
        let url = NodeEditorPersistence.graphURL
        if FileManager.default.fileExists(atPath: url.path) {
            // Save current state, remove, test, restore
            let backup = try? Data(contentsOf: url)
            try FileManager.default.removeItem(at: url)
            let result = NodeEditorPersistence.load()
            #expect(result == nil, "Load should return nil when file doesn't exist")
            // Restore
            if let backup {
                try backup.write(to: url)
            }
        } else {
            let result = NodeEditorPersistence.load()
            #expect(result == nil, "Load should return nil when file doesn't exist")
        }
    }

    @Test func loadCorruptFileReturnsNil() throws {
        let url = NodeEditorPersistence.graphURL
        // Save current state
        let backup = try? Data(contentsOf: url)
        // Write corrupt data
        try "this is not valid json {{{".data(using: .utf8)!.write(to: url)
        let result = NodeEditorPersistence.load()
        #expect(result == nil, "Load should return nil for corrupt JSON")
        // Restore
        if let backup {
            try backup.write(to: url)
        } else {
            try? FileManager.default.removeItem(at: url)
        }
    }

    @Test func saveOverwritesPrevious() throws {
        // Save graph A, then graph B, load should return B
        var graphA = NodeGraph()
        graphA.addNode(ScriptNode(kind: .start, position: .zero))

        var graphB = NodeGraph()
        graphB.addNode(ScriptNode(kind: .start, position: .zero))
        graphB.addNode(ScriptNode(kind: .number, position: .zero, numberValue: 99))

        NodeEditorPersistence.save(graphA)
        NodeEditorPersistence.save(graphB)
        let loaded = NodeEditorPersistence.load()
        #expect(loaded?.nodes.count == 2, "Should load the most recently saved graph")
    }

    @Test func graphURLIsInApplicationSupport() throws {
        let url = NodeEditorPersistence.graphURL
        #expect(url.path.contains("Application Support"), "Graph URL should be in Application Support")
        #expect(url.lastPathComponent == "NodeEditorGraph.json")
    }
}
