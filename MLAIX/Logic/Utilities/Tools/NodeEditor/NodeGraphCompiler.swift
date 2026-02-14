//
//  NodeGraphCompiler.swift
//  MLAIX
//
//  Compiles a NodeGraph to JavaScript (JavaScriptCore) for execution.
//

import Foundation

enum NodeGraphCompiler {
    /// Generates JavaScript code from the graph. Entry is the first "start" node; execution flows via connections. Last expression is the value connected to Output.
    static func compile(_ graph: NodeGraph) throws -> String {
        guard let startNode = graph.nodes.first(where: { $0.kind == .start }) else {
            throw CompileError.noStartNode
        }
        var emitted = Set<UUID>()
        var lines: [String] = []
        var resultVar: String?
        try emitNode(startNode.id, graph: graph, emitted: &emitted, lines: &lines, nodeIdsByVar: [:], resultVar: &resultVar)
        if let r = resultVar {
            lines.append(r)
        }
        return lines.joined(separator: "\n")
    }

    private static func emitNode(
        _ nodeId: UUID,
        graph: NodeGraph,
        emitted: inout Set<UUID>,
        lines: inout [String],
        nodeIdsByVar: [UUID: String],
        resultVar: inout String?
    ) throws {
        guard !emitted.contains(nodeId) else { return }
        guard let node = graph.nodes.first(where: { $0.id == nodeId }) else { return }
        emitted.insert(nodeId)
        let varName = "n_\(nodeId.uuidString.prefix(8))"

        switch node.kind {
        case .start:
            let outConns = graph.connections.filter { $0.fromNodeId == nodeId && $0.fromSlot == "out" }
            for c in outConns {
                try emitNode(c.toNodeId, graph: graph, emitted: &emitted, lines: &lines, nodeIdsByVar: nodeIdsByVar, resultVar: &resultVar)
            }
        case .number:
            lines.append("const \(varName) = \(node.numberValue);")
            try emitOutgoing(nodeId, graph: graph, emitted: &emitted, lines: &lines, nodeIdsByVar: nodeIdsByVar, resultVar: &resultVar)
        case .string:
            let escaped = node.stringValue.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
            lines.append("const \(varName) = \"\(escaped)\";")
            try emitOutgoing(nodeId, graph: graph, emitted: &emitted, lines: &lines, nodeIdsByVar: nodeIdsByVar, resultVar: &resultVar)
        case .add:
            let aVar = try resolveInput(nodeId, slot: "a", graph: graph, emitted: &emitted, lines: &lines, nodeIdsByVar: nodeIdsByVar, resultVar: &resultVar)
            let bVar = try resolveInput(nodeId, slot: "b", graph: graph, emitted: &emitted, lines: &lines, nodeIdsByVar: nodeIdsByVar, resultVar: &resultVar)
            lines.append("const \(varName) = (\(aVar)) + (\(bVar));")
            try emitOutgoing(nodeId, graph: graph, emitted: &emitted, lines: &lines, nodeIdsByVar: nodeIdsByVar, resultVar: &resultVar)
        case .log:
            let valueVar = try resolveInput(nodeId, slot: "value", graph: graph, emitted: &emitted, lines: &lines, nodeIdsByVar: nodeIdsByVar, resultVar: &resultVar)
            lines.append("console.log(\(valueVar));")
            lines.append("const \(varName) = \(valueVar);")
            try emitOutgoing(nodeId, graph: graph, emitted: &emitted, lines: &lines, nodeIdsByVar: nodeIdsByVar, resultVar: &resultVar)
        case .runJS:
            if !node.runJSCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let escaped = node.runJSCode
                    .replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "`", with: "\\`")
                lines.append("const \(varName) = (function(){ \(escaped) })();")
            } else {
                lines.append("const \(varName) = undefined;")
            }
            try emitOutgoing(nodeId, graph: graph, emitted: &emitted, lines: &lines, nodeIdsByVar: nodeIdsByVar, resultVar: &resultVar)
        case .output:
            let valueVar = try resolveInput(nodeId, slot: "value", graph: graph, emitted: &emitted, lines: &lines, nodeIdsByVar: nodeIdsByVar, resultVar: &resultVar)
            resultVar = valueVar
        }
    }

    private static func resolveInput(
        _ toNodeId: UUID,
        slot: String,
        graph: NodeGraph,
        emitted: inout Set<UUID>,
        lines: inout [String],
        nodeIdsByVar: [UUID: String],
        resultVar: inout String?
    ) throws -> String {
        guard let conn = graph.connections.first(where: { $0.toNodeId == toNodeId && $0.toSlot == slot }) else {
            throw CompileError.missingInput(nodeId: toNodeId, slot: slot)
        }
        guard graph.nodes.contains(where: { $0.id == conn.fromNodeId }) else {
            throw CompileError.unknownNode(conn.fromNodeId)
        }
        try emitNode(conn.fromNodeId, graph: graph, emitted: &emitted, lines: &lines, nodeIdsByVar: nodeIdsByVar, resultVar: &resultVar)
        return "n_\(conn.fromNodeId.uuidString.prefix(8))"
    }

    private static func emitOutgoing(
        _ nodeId: UUID,
        graph: NodeGraph,
        emitted: inout Set<UUID>,
        lines: inout [String],
        nodeIdsByVar: [UUID: String],
        resultVar: inout String?
    ) throws {
        let outConns = graph.connections.filter { $0.fromNodeId == nodeId && $0.fromSlot == "out" }
        for c in outConns {
            try emitNode(c.toNodeId, graph: graph, emitted: &emitted, lines: &lines, nodeIdsByVar: nodeIdsByVar, resultVar: &resultVar)
        }
    }

    enum CompileError: LocalizedError {
        case noStartNode
        case missingInput(nodeId: UUID, slot: String)
        case unknownNode(UUID)

        var errorDescription: String? {
            switch self {
            case .noStartNode:
                return String(localized: "Graph must have a Start node.")
            case .missingInput(let nodeId, let slot):
                return String(localized: "Node \(nodeId.uuidString) is missing input for slot \"\(slot)\".")
            case .unknownNode(let id):
                return String(localized: "Unknown node \(id.uuidString).")
            }
        }
    }
}
