//
//  NodeEditorPersistence.swift
//  MLAIX
//
//  Save/load NodeGraph to Application Support.
//

import Foundation

enum NodeEditorPersistence {
    private static let fileName = "NodeEditorGraph.json"

    static var graphURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("MLAIX", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(fileName)
    }

    static func load() -> NodeGraph? {
        let data = try? Data(contentsOf: graphURL)
        guard let data else { return nil }
        return try? JSONDecoder().decode(NodeGraph.self, from: data)
    }

    static func save(_ graph: NodeGraph) {
        guard let data = try? JSONEncoder().encode(graph) else { return }
        try? data.write(to: graphURL)
    }
}
