//
//  ConversationQuickPromptsView.swift
//  MLAI
//
//  Created by Bean John on 10/10/24.
//

import SwiftUI

struct ConversationQuickPromptsView: View {
	
	@Binding var input: String
	
	var body: some View {
        prompts
	}
	
	var prompts: some View {
        WrappingHStack(
            alignment: .leading,
            horizontalSpacing: 8,
            verticalSpacing: 8
        ) {
            ForEach(QuickPrompt.quickPrompts) { prompt in
                QuickPromptButton(
                    input: $input,
                    prompt: prompt
                )
            }
        }
        .padding(.horizontal, 14)
	}
	
}
