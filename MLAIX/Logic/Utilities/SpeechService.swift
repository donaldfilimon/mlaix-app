//
//  SpeechService.swift
//  MLAI
//
//  Created by John Bean on 3/22/25.
//

import AVFoundation
import Foundation
import OSLog
import SwiftUI
import Synchronization

/// Thread-safe delegate for AVSpeechSynthesizer callbacks.
/// Closures are protected by Mutex to prevent data races between @MainActor
/// setter calls and AVFoundation's arbitrary-thread delegate callbacks.
class SpeechSynthesizerDelegate: NSObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {
	private static let logger = Logger(subsystem: Bundle.main.logSubsystem, category: "SpeechSynthesizerDelegate")

	private let _onSpeechFinished = Mutex<(@Sendable () -> Void)?>(nil)
	private let _onSpeechStart = Mutex<(@Sendable () -> Void)?>(nil)

	var onSpeechFinished: (@Sendable () -> Void)? {
		get { _onSpeechFinished.withLock { $0 } }
		set { _onSpeechFinished.withLock { $0 = newValue } }
	}

	var onSpeechStart: (@Sendable () -> Void)? {
		get { _onSpeechStart.withLock { $0 } }
		set { _onSpeechStart.withLock { $0 = newValue } }
	}

	func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
		onSpeechFinished?()
	}

	func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
		onSpeechStart?()
	}

	func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didReceiveError error: Error, for utterance: AVSpeechUtterance, at characterIndex: UInt) {
		Self.logger.error("Speech synthesis error: \(error.localizedDescription, privacy: .public)")
	}
}

@MainActor @Observable
final class SpeechSynthesizer {

	/// A `Logger` object for the ``SpeechSynthesizer`` object
	private static let logger: Logger = .init(
		subsystem: Bundle.main.logSubsystem,
		category: String(describing: SpeechSynthesizer.self)
	)

	/// Static global singleton instance of ``SpeechSynthesizer``
	static let shared = SpeechSynthesizer()
	/// The system speech synthesizer
	private let synthesizer = AVSpeechSynthesizer()
	/// The delegate to handle TTS requests
	private let delegate = SpeechSynthesizerDelegate()

	var isSpeaking = false
	var voices: [AVSpeechSynthesisVoice] = []

	init() {
		self.synthesizer.delegate = self.delegate
		self.fetchVoices()
	}

	/// Function to get the ID of the currently selected voice
	private func getVoiceIdentifier() -> String? {
		let voiceIdentifier = UserDefaults.standard.string(forKey: "voiceId")
		if let voice = voices.first(where: {$0.identifier == voiceIdentifier}) {
			return voice.identifier
		}

		return voices.first?.identifier
	}

	var lastCancelation: (@Sendable () -> Void)? = {}

	/// Function to perform TTS on a `String`
	public func speak(
		text: String,
		onFinished: @escaping @Sendable () -> Void = {}
	) async {
		// Get voice
		guard let voiceIdentifier: String = getVoiceIdentifier() else {
			Self.logger.error("Could not find selected voice identifier")
			return
		}
		lastCancelation = onFinished
		delegate.onSpeechFinished = { @Sendable [weak self] in
			Task { @MainActor in
				withAnimation {
					self?.isSpeaking = false
				}
				onFinished()
			}
		}
		delegate.onSpeechStart = { @Sendable [weak self] in
			Task { @MainActor in
				withAnimation(.linear) {
					self?.isSpeaking = true
				}
			}
		}
		let utterance = AVSpeechUtterance(string: text)
		utterance.voice = AVSpeechSynthesisVoice(identifier: voiceIdentifier)
		utterance.rate = 0.52 // Slightly faster than medium speed
		synthesizer.speak(utterance)
	}

	/// Function to stop current TTS task
	public func stopSpeaking() async {
		withAnimation(.linear) {
			self.isSpeaking = false
		}
		lastCancelation?()
		synthesizer.stopSpeaking(at: .immediate)
	}

	/// Function to fetch list of all available voices
	public func fetchVoices() {
		let voices = AVSpeechSynthesisVoice.speechVoices().sorted { (firstVoice: AVSpeechSynthesisVoice, secondVoice: AVSpeechSynthesisVoice) -> Bool in
			return firstVoice.quality.rawValue > secondVoice.quality.rawValue
		}
		// Prevent state refresh if there are no new elements
		let diff = self.voices.elementsEqual(voices, by: { $0.identifier == $1.identifier })
		if diff {
			return
		}
		Task { @MainActor in
			self.voices = voices
		}
	}

}
