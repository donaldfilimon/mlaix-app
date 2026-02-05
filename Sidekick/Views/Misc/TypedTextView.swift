//
//  TypedTextView.swift
//  Sidekick
//
//  Created by Bean John on 10/31/24.
//

import SwiftUI

struct TypedTextView: View {

	init(
		_ text: String,
		duration: Double = 1.0,
		didFinish: Binding<Bool>,
		onFinish: (@MainActor () -> Void)? = nil
	) {
		self.text = text
		self.duration = duration
		self._didFinish = didFinish
		self.onFinish = onFinish
	}

	var text: String
	var duration: Double
	var onFinish: (@MainActor () -> Void)?

	@Binding var didFinish: Bool
	@State private var displayedText: String = ""
	@State private var typingTask: Task<Void, Never>?

	var body: some View {
		Group {
			Text(displayedText)
		}
		.onAppear {
			startTyping()
		}
		.onChange(of: text) {
			startTyping()
		}
		.onDisappear {
			typingTask?.cancel()
		}
	}

	private func startTyping() {
		// Cancel any existing typing task
		typingTask?.cancel()

		// Reset state
		displayedText = ""
		didFinish = false

		guard !text.isEmpty else {
			didFinish = true
			onFinish?()
			return
		}

		let interval = duration / Double(text.count)
		let textToType = text

		typingTask = Task { @MainActor in
			for index in 0..<textToType.count {
				guard !Task.isCancelled else { return }

				try? await Task.sleep(for: .seconds(interval))

				guard !Task.isCancelled else { return }

				let character: String = textToType[index]
				displayedText.append(character)
			}

			guard !Task.isCancelled else { return }

			didFinish = true
			onFinish?()
		}
	}
	
	
	
}
