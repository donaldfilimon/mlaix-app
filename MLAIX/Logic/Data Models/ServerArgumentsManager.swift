//
//  ServerArgumentsManager.swift
//  MLAI
//
//  Created by John Bean on 4/29/25.
//

import Foundation
import MLAIXShared
import Observation
import OSLog
import SwiftData
import SwiftUI

@MainActor
@Observable
public class ServerArgumentsManager {
    
    /// A `Logger` object for the ``ServerArgumentsManager`` object
    private static let logger: Logger = .init(
        subsystem: Bundle.main.logSubsystem,
        category: String(describing: ServerArgumentsManager.self)
    )
    
    init() {
        self.patchFileIntegrity()
        self.load()
    }
    
    /// Static constant for the global `ServerArgumentsManager` object
    static public let shared: ServerArgumentsManager = .init()
    
    /// Published property for all serverArguments
    public var serverArguments: [ServerArgument] = ServerArgument.defaultServerArguments {
        didSet {
            self.save()
        }
    }
    
    /// A list of active arguments
    public var activeArguments: [ServerArgument] {
        return self.serverArguments
            .filter(\.isActive)
            .filter { argument in
                return !argument.flag.isEmpty
            }
    }
    /// A `String` for all the arguments that need to be appended
    public var allArguments: [String] {
        return self.activeArguments.map { argument in
            return argument.arguments
        }.reduce([], +)
    }
    
    /// Saves server arguments to disk (SwiftData when migrated, otherwise JSON).
    public func save() {
        if DataMigrationService.didMigrateToSwiftData, let context = SwiftDataStore.mainContext {
            saveToSwiftData(context: context)
            return
        }
        do {
            let rawData = try JSONEncoder().encode(self.serverArguments)
            try rawData.write(to: self.datastoreUrl, options: .atomic)
        } catch {
            Self.logger.error("Failed to save server arguments: \(error.localizedDescription)")
        }
    }

    private func saveToSwiftData(context: ModelContext) {
        do {
            var descriptor = FetchDescriptor<ServerArgumentModel>(sortBy: [SortDescriptor(\.flag)])
            descriptor.fetchLimit = 0
            let existing = try context.fetch(descriptor)
            for model in existing {
                context.delete(model)
            }
            for arg in serverArguments {
                let model = ServerArgumentModel(
                    id: arg.id,
                    flag: arg.flag,
                    value: arg.value,
                    isActive: arg.isActive
                )
                context.insert(model)
            }
            try context.save()
        } catch {
            Self.logger.error("Failed to save server arguments to SwiftData: \(error.localizedDescription)")
        }
    }

    /// Loads server arguments from disk (SwiftData when migrated, otherwise JSON).
    public func load() {
        if DataMigrationService.didMigrateToSwiftData, let context = SwiftDataStore.mainContext {
            loadFromSwiftData(context: context)
            return
        }
        do {
            let rawData = try Data(contentsOf: self.datastoreUrl)
            let decoder = JSONDecoder()
            self.serverArguments = try decoder.decode([ServerArgument].self, from: rawData)
        } catch {
            Self.logger.error("Failed to load serverArguments: \(error.localizedDescription, privacy: .public)")
            self.newDatastore()
        }
    }

    private func loadFromSwiftData(context: ModelContext) {
        do {
            let descriptor = FetchDescriptor<ServerArgumentModel>(sortBy: [SortDescriptor(\.flag)])
            let models = try context.fetch(descriptor)
            serverArguments = models.map { ServerArgument(id: $0.id, isActive: $0.isActive, flag: $0.flag, value: $0.value) }
        } catch {
            Self.logger.error("Failed to load server arguments from SwiftData: \(error.localizedDescription)")
            newDatastore()
        }
    }
    
    /// Function to delete a serverArguments
    public func delete(_ serverArguments: Binding<ServerArgument>) {
        withAnimation(.spring()) {
            self.serverArguments = self.serverArguments.filter {
                $0.id != serverArguments.wrappedValue.id
            }
        }
    }
    
    /// Function to delete a serverArguments
    public func delete(_ serverArguments: ServerArgument) {
        withAnimation(.spring()) {
            self.serverArguments = self.serverArguments.filter {
                $0.id != serverArguments.id
            }
        }
    }
    
    /// Function to add a serverArguments
    public func add(_ serverArguments: ServerArgument) {
        withAnimation(.spring()) {
            self.serverArguments.append(serverArguments)
        }
    }
    
    /// Function to update a serverArguments
    public func update(_ serverArguments: ServerArgument) {
        withAnimation(.spring()) {
            for serverArgumentsIndex in self.serverArguments.indices {
                if serverArguments.id == self.serverArguments[serverArgumentsIndex].id {
                    self.serverArguments[serverArgumentsIndex] = serverArguments
                    break
                }
            }
        }
    }
    
    /// Function to update a serverArguments
    public func update(_ serverArguments: Binding<ServerArgument>) {
        withAnimation(.spring()) {
            let targetId: UUID = serverArguments.wrappedValue.id
            for index in self.serverArguments.indices {
                if targetId == self.serverArguments[index].id {
                    self.serverArguments[index] = serverArguments.wrappedValue
                    break
                }
            }
        }
    }
    
    /// Function to make new datastore
    public func newDatastore() {
        // Setup directory
        self.patchFileIntegrity()
        // Add new datastore
        self.serverArguments = ServerArgument.defaultServerArguments
        self.save()
    }
    
    /// Function to reset datastore
    @MainActor
    public func resetDatastore() {
        // Present confirmation modal
        let _ = Dialogs.showConfirmation(
            title: String(localized: "Delete All Server Arguments"),
            message: String(localized: "Are you sure you want to delete all server arguments?")
        ) {
            // If yes, delete datastore
            FileManager.removeItem(at: self.datastoreUrl)
            // Make new datastore
            self.newDatastore()
        }
    }
    
    /// Function to patch file integrity
    public func patchFileIntegrity() {
        // Setup directory if needed
        if !self.datastoreDirExists {
            do {
                try FileManager.default.createDirectory(
                    at: datastoreDirUrl,
                    withIntermediateDirectories: true
                )
            } catch {
                Logger(subsystem: Bundle.main.logSubsystem, category: "ServerArgumentsManager").error("Failed to create datastore directory: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
    
    /// Computed property returning the datastore's directory's url
    public var datastoreDirUrl: URL {
        return Settings.containerUrl.appendingPathComponent(
            "Server Arguments"
        )
    }
    
    /// Computed property returning if datastore directory exists
    private var datastoreDirExists: Bool {
        return self.datastoreDirUrl.fileExists
    }
    
    /// Computed property returning the datastore's url
    public var datastoreUrl: URL {
        return self.datastoreDirUrl.appendingPathComponent(
            "serverArguments.json"
        )
    }
    
    /// Computed property returning if datastore exists
    private var datastoreExists: Bool {
        return self.datastoreUrl.fileExists
    }
    
}

