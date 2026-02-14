//
//  ContentView.swift
//  MLAI
//
//  Created by Bean John on 10/4/24.
//

import FSKit_macOS
import SwiftUI

struct ContentView: View {

	@Environment(DownloadManager.self) private var downloadManager
	@Environment(ExpertManager.self) private var expertManager
	@Environment(ConversationManager.self) private var conversationManager

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
		.observeWindowCommands()
    }
}

#Preview {
    ContentView()
        .environment(AppState.shared)
        .environment(DownloadManager.shared)
        .environment(ExpertManager.shared)
        .environment(ConversationManager.shared)
		.environment(Model.shared)
}
