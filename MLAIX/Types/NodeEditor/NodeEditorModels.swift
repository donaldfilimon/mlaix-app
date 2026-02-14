//
//  NodeEditorModels.swift
//  MLAIX
//
//  Data model for the node-based scripting editor (nodes, connections, graph).
//

import Foundation
import CoreGraphics

/// Kind of node in the script graph.
public enum NodeKind: String, CaseIterable, Identifiable, Codable {
    case start
    case number
    case string
    case add
    case log
    case runJS
    case output

    public var id: String { rawValue }

    var title: String {
        switch self {
        case .start: return String(localized: "Start")
        case .number: return String(localized: "Number")
        case .string: return String(localized: "String")
        case .add: return String(localized: "Add")
        case .log: return String(localized: "Log")
        case .runJS: return String(localized: "Run JS")
        case .output: return String(localized: "Output")
        }
    }

    var inputSlots: [String] {
        switch self {
        case .start: return []
        case .number, .string, .runJS: return []
        case .add: return ["a", "b"]
        case .log: return ["value"]
        case .output: return ["value"]
        }
    }

    var outputSlots: [String] {
        switch self {
        case .start: return ["out"]
        case .number, .string, .runJS: return ["out"]
        case .add, .log: return ["out"]
        case .output: return []
        }
    }
}

/// A single node in the graph.
public struct ScriptNode: Identifiable, Codable, Hashable {
    public var id: UUID
    public var kind: NodeKind
    public var position: CGPoint
    public var numberValue: Double
    public var stringValue: String
    public var runJSCode: String

    public init(
        id: UUID = UUID(),
        kind: NodeKind,
        position: CGPoint = .zero,
        numberValue: Double = 0,
        stringValue: String = "",
        runJSCode: String = ""
    ) {
        self.id = id
        self.kind = kind
        self.position = position
        self.numberValue = numberValue
        self.stringValue = stringValue
        self.runJSCode = runJSCode
    }

    private enum CodingKeys: String, CodingKey {
        case id, kind, positionX, positionY, numberValue, stringValue, runJSCode
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        kind = try c.decode(NodeKind.self, forKey: .kind)
        let x = try c.decode(Double.self, forKey: .positionX)
        let y = try c.decode(Double.self, forKey: .positionY)
        position = CGPoint(x: x, y: y)
        numberValue = try c.decode(Double.self, forKey: .numberValue)
        stringValue = try c.decode(String.self, forKey: .stringValue)
        runJSCode = try c.decode(String.self, forKey: .runJSCode)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(kind, forKey: .kind)
        try c.encode(Double(position.x), forKey: .positionX)
        try c.encode(Double(position.y), forKey: .positionY)
        try c.encode(numberValue, forKey: .numberValue)
        try c.encode(stringValue, forKey: .stringValue)
        try c.encode(runJSCode, forKey: .runJSCode)
    }
}

/// A connection from one node's output to another's input.
public struct ScriptConnection: Identifiable, Codable, Hashable {
    public var id: UUID
    public var fromNodeId: UUID
    public var fromSlot: String
    public var toNodeId: UUID
    public var toSlot: String

    public init(
        id: UUID = UUID(),
        fromNodeId: UUID,
        fromSlot: String,
        toNodeId: UUID,
        toSlot: String
    ) {
        self.id = id
        self.fromNodeId = fromNodeId
        self.fromSlot = fromSlot
        self.toNodeId = toNodeId
        self.toSlot = toSlot
    }
}

/// Full node graph (script).
public struct NodeGraph: Codable, Equatable {
    public var nodes: [ScriptNode]
    public var connections: [ScriptConnection]

    public init(nodes: [ScriptNode] = [], connections: [ScriptConnection] = []) {
        self.nodes = nodes
        self.connections = connections
    }

    public mutating func addNode(_ node: ScriptNode) {
        nodes.append(node)
    }

    public mutating func removeNode(id: UUID) {
        nodes.removeAll { $0.id == id }
        connections.removeAll { $0.fromNodeId == id || $0.toNodeId == id }
    }

    public mutating func addConnection(_ c: ScriptConnection) {
        guard !connections.contains(where: { $0.toNodeId == c.toNodeId && $0.toSlot == c.toSlot }) else { return }
        connections.append(c)
    }

    public mutating func removeConnection(id: UUID) {
        connections.removeAll { $0.id == id }
    }
}
