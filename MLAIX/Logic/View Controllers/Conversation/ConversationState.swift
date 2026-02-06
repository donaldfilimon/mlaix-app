//
//  ConversationState.swift
//  MLAI
//
//  Created by Bean John on 10/14/24.
//

import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
public final class ConversationState {

	var isManagingExperts: Bool = false
	var selectedConversationId: UUID? = ConversationState.topmostConversation?.id

	/// The topmost conversation listed in the sidebar
	private static var topmostConversation: Conversation? {
		ConversationManager.shared.conversations.first
	}

	/// The currently selected conversation
	public var selectedConversation: Conversation? {
		guard let selectedConversationId else { return nil }
		return ConversationManager.shared.getConversation(id: selectedConversationId)
	}

	var selectedExpertId: UUID? = ConversationManager.shared.conversations.first?.messages.last?.expertId ?? ExpertManager.shared.default?.id
	var useCanvas: Bool = false
	
	/// Function to create a new conversation
	public func newConversation() {
		// Create new conversation
		ConversationManager.shared.newConversation()
		// Reset selected expert
		withAnimation(.linear) {
			self.selectedExpertId = ExpertManager.shared.default?.id
		}
		// Select newly created conversation
		if let recentConversationId = ConversationManager.shared.recentConversation?.id {
			withAnimation(.linear) {
				self.selectedConversationId = recentConversationId
			}
		}
	}
	
}
