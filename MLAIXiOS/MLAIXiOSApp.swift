//
//  MLAIXiOSApp.swift
//  MLAIX iOS / iPadOS
//

import MLAIXShared
import SwiftData
import SwiftUI

@main
struct MLAIXiOSApp: App {
    @State private var chatState: iOSChatState

    init() {
        let schema = Schema([
            SharedConversation.self,
            SharedChatMessage.self,
            MemoryModel.self,
            CommandModel.self,
            InferenceRecordModel.self,
            ServerArgumentModel.self,
            FunctionSelectionModel.self
        ])
        let fileConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container: ModelContainer
        if let c = try? ModelContainer(for: schema, configurations: [fileConfig]) {
            container = c
        } else if let c = try? ModelContainer(for: schema, configurations: [memoryConfig]) {
            container = c
        } else {
            preconditionFailure("SwiftData container failed: disk and in-memory initialization both failed. Check storage permissions.")
        }
        let ctx = ModelContext(container)
        _chatState = State(wrappedValue: iOSChatState(modelContext: ctx))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(chatState)
        }
    }
}
