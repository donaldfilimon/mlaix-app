//
//  NodeEditorPersistence.swift
//  MLAIX
//
//  Save/load NodeGraph to Application Support.
//

import Foundation
import os.log

enum NodeEditorPersistence {
    private static let logger = Logger(subsystem: "com.mlaix", category: "NodeEditorPersistence")
    private static let fileName = "NodeEditorGraph.json"

    static var graphURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("MLAIX", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(fileName)
    }

    static func load() -> NodeGraph? {
        let url = graphURL
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(NodeGraph.self, from: data)
        } catch {
            logger.error("Failed to load node graph: \(error.localizedDescription)")
            return nil
        }
    }

    static func save(_ graph: NodeGraph) {
        do {
            let data = try JSONEncoder().encode(graph)
            try data.write(to: graphURL)
        } catch {
            logger.error("Failed to save node graph: \(error.localizedDescription)")
        }
    }
}
