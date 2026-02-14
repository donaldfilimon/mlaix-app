//
//  CommandManager.swift
//  MLAI
//
//  Created by Bean John on 11/18/24.
//

import Foundation
import MLAIXShared
import Observation
import OSLog
import SwiftData
import SwiftUI

@MainActor
@Observable
public class CommandManager {
    
    /// A `Logger` object for the ``CommandManager`` object
    private static let logger: Logger = .init(
        subsystem: Bundle.main.logSubsystem,
        category: String(describing: CommandManager.self)
    )
    
    init() {
        let signpost = StartupMetrics.beginInterval("CommandManager.init")
        self.patchFileIntegrity()
        self.loadAsync()
        StartupMetrics.endInterval("CommandManager.init", signpost)
    }
    
    /// Static constant for the global ``CommandManager`` object
    static public let shared: CommandManager = .init()
    
    /// Published property for all commands
    public var commands: [Command] = [] {
        didSet {
            self.save()
        }
    }
    
    /// Published state tracking whether the datastore has been loaded
    private(set) var isLoaded: Bool = false
    
    /// Task handling asynchronous datastore loading
    private var loadTask: Task<Void, Never>?
    
    /// Computed property returning the first command
    var firstCommand: Command? {
        if self.commands.first == nil {
            self.newDatastore()
        }
        return self.commands.first
    }
    
    /// Computed property returning the last command
    var lastCommand: Command? {
        if self.commands.last == nil {
            self.newDatastore()
        }
        return self.commands.last
    }
    
    /// Function to create a new command
    public func addCommand(
        command: Command
    ) {
        // Add to commands
        self.commands.append(command)
    }
    
    /// Function returning a command with the given ID
    public func getCommand(
        id commandId: UUID
    ) -> Command? {
        return self.commands.filter({ $0.id == commandId }).first
    }
    
    /// Function to save commands to disk (SwiftData when migrated, otherwise JSON).
    public func save() {
        if DataMigrationService.didMigrateToSwiftData, let context = SwiftDataStore.mainContext {
            saveToSwiftData(context: context)
            return
        }
        do {
            let rawData: Data = try JSONEncoder().encode(self.commands)
            try rawData.write(to: self.datastoreUrl, options: .atomic)
        } catch {
            Self.logger.error("Failed to save commands: \(error.localizedDescription)")
        }
    }

    private func saveToSwiftData(context: ModelContext) {
        do {
            var descriptor = FetchDescriptor<CommandModel>(sortBy: [SortDescriptor(\.name)])
            descriptor.fetchLimit = 0
            let existing = try context.fetch(descriptor)
            for model in existing {
                context.delete(model)
            }
            for command in commands {
                let model = CommandModel(
                    id: command.id,
                    name: command.name,
                    prompt: command.prompt,
                    symbolName: "text.bubble"
                )
                context.insert(model)
            }
            try context.save()
        } catch {
            Self.logger.error("Failed to save commands to SwiftData: \(error.localizedDescription)")
        }
    }
    
    /// Loads commands in the background (from SwiftData when migrated, otherwise JSON).
    private func loadAsync() {
        if let loadTask = self.loadTask, !loadTask.isCancelled {
            return
        }
        if DataMigrationService.didMigrateToSwiftData, let context = SwiftDataStore.mainContext {
            loadTask = Task { @MainActor [weak self] in
                guard let self else { return }
                let signpost = StartupMetrics.beginInterval("CommandManager.loadDatastore")
                defer { StartupMetrics.endInterval("CommandManager.loadDatastore", signpost) }
                self.loadFromSwiftData(context: context)
                self.loadTask = nil
            }
            return
        }
        let targetUrl: URL = self.datastoreUrl
        loadTask = Task.detached(priority: .userInitiated) {
            let signpost = StartupMetrics.beginInterval("CommandManager.loadDatastore")
            defer { StartupMetrics.endInterval("CommandManager.loadDatastore", signpost) }
            let rawData: Data
            do {
                rawData = try Data(contentsOf: targetUrl)
            } catch {
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.newDatastore()
                    self.isLoaded = true
                    self.loadTask = nil
                }
                return
            }
            let decoder = JSONDecoder()
            let commands = (try? decoder.decode([Command].self, from: rawData)) ?? []
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.commands = commands
                self.isLoaded = true
                self.loadTask = nil
            }
        }
    }

    private func loadFromSwiftData(context: ModelContext) {
        do {
            let descriptor = FetchDescriptor<CommandModel>(sortBy: [SortDescriptor(\.name)])
            let models = try context.fetch(descriptor)
            commands = models.map { Command(id: $0.id, name: $0.name, prompt: $0.prompt) }
            isLoaded = true
        } catch {
            Self.logger.error("Failed to load commands from SwiftData: \(error.localizedDescription)")
            newDatastore()
            isLoaded = true
        }
    }
    
    /// Function to load commands from disk (SwiftData when migrated, otherwise JSON).
    public func load() {
        if DataMigrationService.didMigrateToSwiftData, let context = SwiftDataStore.mainContext {
            loadFromSwiftData(context: context)
            return
        }
        do {
            let rawData = try Data(contentsOf: self.datastoreUrl)
            let decoder = JSONDecoder()
            self.commands = try decoder.decode([Command].self, from: rawData)
            self.isLoaded = true
        } catch {
            Self.logger.error("Failed to load commands: \(error.localizedDescription, privacy: .public)")
            self.newDatastore()
        }
    }
    
    /// Function to delete a command
    public func delete(_ command: Binding<Command>) {
        withAnimation(.spring()) {
            self.commands = self.commands.filter {
                $0.id != command.wrappedValue.id
            }
        }
    }
    
    /// Function to delete a command
    public func delete(_ command: Command) {
        withAnimation(.spring()) {
            self.commands = self.commands.filter {
                $0.id != command.id
            }
        }
    }
    
    /// Function to add a command
    public func add(_ command: Command) {
        withAnimation(.linear) {
            self.commands.append(command)
            self.commands = self.commands.sorted(by: \.name)
        }
    }
    
    /// Function to update a command
    public func update(_ command: Command) {
        withAnimation(.spring()) {
            for commandIndex in self.commands.indices {
                if command.id == self.commands[commandIndex].id {
                    self.commands[commandIndex] = command
                    break
                }
            }
        }
    }
    
    /// Function to update a command
    public func update(_ command: Binding<Command>) {
        withAnimation(.spring()) {
            let targetId: UUID = command.wrappedValue.id
            for index in self.commands.indices {
                if targetId == self.commands[index].id {
                    self.commands[index] = command.wrappedValue
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
        self.commands = Command.defaults
        self.isLoaded = true
        self.save()
    }
    
    /// Function to reset datastore
    @MainActor
    public func resetDatastore() {
        let _ = Dialogs.showConfirmation(
            title: String(localized: "Delete All Commands"),
            message: String(localized: "Are you sure you want to delete all commands?")
        ) {
            if !DataMigrationService.didMigrateToSwiftData {
                FileManager.removeItem(at: self.datastoreUrl)
            }
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
                Logger(subsystem: Bundle.main.logSubsystem, category: "CommandManager").error("Failed to create datastore directory: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
    
    /// Computed property returning the datastore's directory's url
    public var datastoreDirUrl: URL {
        return Settings.containerUrl.appendingPathComponent(
            "Commands"
        )
    }
    
    /// Computed property returning if datastore directory exists
    private var datastoreDirExists: Bool {
        return self.datastoreDirUrl.fileExists
    }
    
    /// Computed property returning the datastore's url
    public var datastoreUrl: URL {
        return self.datastoreDirUrl.appendingPathComponent(
            "commands.json"
        )
    }
    
    /// Computed property returning if datastore exists
    private var datastoreExists: Bool {
        return self.datastoreUrl.fileExists
    }
    
}

