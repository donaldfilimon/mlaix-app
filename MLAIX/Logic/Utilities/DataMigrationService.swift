//
//  DataMigrationService.swift
//  MLAIX
//
//  Handles one-time migration of JSON file datastores to SwiftData.
//

import Foundation
import MLAIXShared
import OSLog
import SwiftData
import SwiftUI

/// Handles one-time migration of JSON file datastores to SwiftData.
@MainActor
public struct DataMigrationService {

    private static let logger = Logger(
        subsystem: Bundle.main.logSubsystem,
        category: "DataMigration"
    )
    /// UserDefaults key used to mark that JSON → SwiftData migration has completed.
    public static let migrationKey = "didMigrateToSwiftData_v1"

    /// Whether migration has already run; managers use this to decide whether to load from SwiftData.
    public static var didMigrateToSwiftData: Bool {
        UserDefaults.standard.bool(forKey: migrationKey)
    }

    /// Run migration if needed. Call from app startup.
    public static func migrateIfNeeded(context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: migrationKey) else {
            logger.info("SwiftData migration already completed, skipping")
            return
        }

        logger.info("Starting JSON → SwiftData migration")

        migrateInferenceRecords(context: context)
        migrateMemories(context: context)
        migrateCommands(context: context)
        migrateServerArguments(context: context)
        migrateFunctionSelections(context: context)

        // Save all changes
        do {
            try context.save()
            UserDefaults.standard.set(true, forKey: migrationKey)
            logger.info("JSON → SwiftData migration completed successfully")
        } catch {
            logger.error("Failed to save migration: \(error.localizedDescription)")
        }
    }

    // MARK: - Inference Records

    private static func migrateInferenceRecords(context: ModelContext) {
        let fileUrl = Settings.containerUrl
            .appendingPathComponent("Inference Records")
            .appendingPathComponent("records.json")

        guard FileManager.default.fileExists(atPath: fileUrl.path) else {
            logger.info("No inference records JSON found, skipping")
            return
        }

        do {
            let data = try Data(contentsOf: fileUrl)
            let records = try JSONDecoder().decode([InferenceRecord].self, from: data)
            for record in records {
                let model = InferenceRecordModel(
                    id: record.id,
                    name: record.name,
                    type: record.type.rawValue,
                    inputTokens: record.inputTokens,
                    outputTokens: record.outputTokens,
                    startTime: record.startTime,
                    endTime: record.endTime,
                    usedRemoteServer: record.endpoint != nil
                )
                context.insert(model)
            }
            archiveFile(at: fileUrl)
            logger.info("Migrated \(records.count) inference records")
        } catch {
            logger.error("Failed to migrate inference records: \(error.localizedDescription)")
        }
    }

    // MARK: - Memories

    private static func migrateMemories(context: ModelContext) {
        let fileUrl = Settings.containerUrl
            .appendingPathComponent("Memory")
            .appendingPathComponent("memories.json")

        guard FileManager.default.fileExists(atPath: fileUrl.path) else {
            logger.info("No memories JSON found, skipping")
            return
        }

        do {
            let data = try Data(contentsOf: fileUrl)
            let memories = try JSONDecoder().decode([Memory].self, from: data)
            for memory in memories {
                let model = MemoryModel(
                    id: memory.id,
                    messageId: memory.messageId,
                    text: memory.text,
                    createdAt: memory.createdAt
                )
                context.insert(model)
            }
            archiveFile(at: fileUrl)
            logger.info("Migrated \(memories.count) memories")
        } catch {
            logger.error("Failed to migrate memories: \(error.localizedDescription)")
        }
    }

    // MARK: - Commands

    private static func migrateCommands(context: ModelContext) {
        let fileUrl = Settings.containerUrl
            .appendingPathComponent("Commands")
            .appendingPathComponent("commands.json")

        guard FileManager.default.fileExists(atPath: fileUrl.path) else {
            logger.info("No commands JSON found, skipping")
            return
        }

        do {
            let data = try Data(contentsOf: fileUrl)
            let commands = try JSONDecoder().decode([Command].self, from: data)
            for command in commands {
                let model = CommandModel(
                    id: command.id,
                    name: command.name,
                    prompt: command.prompt,
                    symbolName: "text.bubble"
                )
                context.insert(model)
            }
            archiveFile(at: fileUrl)
            logger.info("Migrated \(commands.count) commands")
        } catch {
            logger.error("Failed to migrate commands: \(error.localizedDescription)")
        }
    }

    // MARK: - Server Arguments

    private static func migrateServerArguments(context: ModelContext) {
        let fileUrl = Settings.containerUrl
            .appendingPathComponent("Server Arguments")
            .appendingPathComponent("serverArguments.json")

        guard FileManager.default.fileExists(atPath: fileUrl.path) else {
            logger.info("No server arguments JSON found, skipping")
            return
        }

        do {
            let data = try Data(contentsOf: fileUrl)
            let args = try JSONDecoder().decode([ServerArgument].self, from: data)
            for arg in args {
                let model = ServerArgumentModel(
                    id: arg.id,
                    flag: arg.flag,
                    value: arg.value,
                    isActive: arg.isActive
                )
                context.insert(model)
            }
            archiveFile(at: fileUrl)
            logger.info("Migrated \(args.count) server arguments")
        } catch {
            logger.error("Failed to migrate server arguments: \(error.localizedDescription)")
        }
    }

    // MARK: - Function Selections

    private static func migrateFunctionSelections(context: ModelContext) {
        let fileUrl = Settings.containerUrl
            .appendingPathComponent("Cache")
            .appendingPathComponent("function_selection.json")

        guard FileManager.default.fileExists(atPath: fileUrl.path) else {
            logger.info("No function selection JSON found, skipping")
            return
        }

        do {
            let data = try Data(contentsOf: fileUrl)
            let categories = try JSONDecoder().decode([FunctionCategory].self, from: data)
            // The JSON stores the *enabled* categories as an array of FunctionCategory raw values.
            let enabledNames = Set(categories.map(\.rawValue))
            // Create a row for every known category, marking it enabled/disabled.
            for category in FunctionCategory.allCases {
                let model = FunctionSelectionModel(
                    categoryName: category.rawValue,
                    isEnabled: enabledNames.contains(category.rawValue)
                )
                context.insert(model)
            }
            archiveFile(at: fileUrl)
            logger.info("Migrated \(categories.count) function selections")
        } catch {
            logger.error("Failed to migrate function selections: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    /// Renames a JSON file to `.json.migrated` so it is not re-read, but is preserved for safety.
    private static func archiveFile(at url: URL) {
        let archivedUrl = url.appendingPathExtension("migrated")
        do {
            try FileManager.default.moveItem(at: url, to: archivedUrl)
            logger.info("Archived \(url.lastPathComponent) → \(archivedUrl.lastPathComponent)")
        } catch {
            logger.warning("Could not archive \(url.lastPathComponent): \(error.localizedDescription)")
        }
    }
}
