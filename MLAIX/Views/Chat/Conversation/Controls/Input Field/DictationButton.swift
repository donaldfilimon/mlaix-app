//
//  DictationButton.swift
//  MLAI
//
//  Created by Bean John on 10/23/24.
//

import SwiftUI

struct DictationButton: View {
	
	@Environment(PromptController.self) private var promptController
	
	private var microphoneIcon: String { "microphone.fill" }
	
    var body: some View {
		Button {
			withAnimation(.linear) {
				self.promptController.toggleRecording()
			}
		} label: {
			Label("", systemImage: self.microphoneIcon)
				.foregroundStyle(
					promptController.isRecording ? .red : .secondary
				)
		}
		.buttonStyle(.plain)
		.keyboardShortcut("d", modifiers: [.command])
		.padding([.trailing, .bottom], 3)
    }
}

#Preview {
    DictationButton()
}
