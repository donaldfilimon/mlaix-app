//
//  ContentView.swift
//  MLAI
//
//  Created by Bean John on 10/4/24.
//

import FSKit_macOS
import SwiftUI

struct ContentView: View {

	@Environment(\.openWindow) private var openWindow
	@EnvironmentObject private var downloadManager: DownloadManager
	@EnvironmentObject private var expertManager: ExpertManager
	@EnvironmentObject private var conversationManager: ConversationManager

	@State private var conversationState = ConversationState()
	
	@State private var showSetup: Bool = Settings.showSetup
	
    var body: some View {
		ConversationManagerView()
		.sheet(isPresented: $showSetup) {
			SetupView(showSetup: $showSetup)
				.environment(conversationState)
		}
		.sheet(isPresented: $conversationState.isManagingExperts) {
			ExpertManagerView()
				.environment(conversationState)
				.frame(minWidth: 300, maxWidth: 450, minHeight: 450, maxHeight: 700)
		}
		.environment(conversationState)
		.onChange(of: showSetup) { _, completed in
			if !completed && conversationManager.conversations.isEmpty {
				conversationState.newConversation()
			}
		}
		.onAppear {
			if !showSetup && conversationManager.conversations.isEmpty {
				conversationState.newConversation()
			}
		}
		.onReceive(NotificationCenter.default.publisher(for: Notifications.showKeyboardShortcuts.name)) { _ in
			openWindow(id: "keyboardShortcuts")
		}
		#if DEBUG
		.onReceive(NotificationCenter.default.publisher(for: Notifications.showScriptTesting.name)) { _ in
			openWindow(id: "scriptTesting")
		}
		#endif
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState.shared)
        .environmentObject(DownloadManager.shared)
        .environmentObject(ExpertManager.shared)
        .environmentObject(ConversationManager.shared)
        .environmentObject(Model.shared)
}
