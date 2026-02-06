//
//  ConversationNavigationListView.swift
//  MLAI
//
//  Created by Bean John on 10/8/24.
//

import SwiftUI

struct ConversationNavigationListView: View {
	
	@EnvironmentObject private var conversationManager: ConversationManager
	@EnvironmentObject private var expertManager: ExpertManager
	@Environment(ConversationState.self) private var conversationState
	
	var body: some View {
		List(
			self.$conversationManager.conversations,
			editActions: .move,
			selection: Bindable(conversationState).selectedConversationId
		) { conversation in
			NavigationLink(value: conversation.id) {
				ConversationNameEditor(conversation: conversation)
			}
        }
        .scrollIndicators(.never)
		.navigationSplitViewColumnWidth(
			min: 125,
			ideal: 175,
			max: 225
		)
	}
	
}
