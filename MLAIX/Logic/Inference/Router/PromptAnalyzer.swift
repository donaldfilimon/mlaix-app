//
//  PromptAnalyzer.swift
//  MLAI
//
//  Created by John Bean on 12/19/24.
//

import CoreML
import Foundation
import ImagePlayground
import NaturalLanguage

public class PromptAnalyzer {

    @MainActor
    private final class Cache {
        static let maxCount = 64
        static var storage: [String: ResultType] = [:]
        static var order: [String] = []

        static func retrieve(_ key: String) -> ResultType? {
            guard let idx = order.firstIndex(of: key) else { return nil }
            order.remove(at: idx)
            order.append(key)
            return storage[key]
        }

        static func store(_ key: String, resultType: ResultType) {
            if storage[key] != nil {
                order.removeAll { $0 == key }
            } else if order.count >= maxCount, let oldest = order.first {
                order.removeFirst()
                storage.removeValue(forKey: oldest)
            }
            storage[key] = resultType
            order.append(key)
        }
    }

	/// Function to detect what results are expected by the prompt
	/// - Parameter prompt: The user's prompt
	/// - Returns: The format of the content to be generated
	@MainActor
	public static func getExpectedResultType(
		_ prompt: String
    ) -> ResultType {
        // Check what types are available
        let resultTypes: [ResultType] = ResultType.allCases.filter(\.isAvailable)
        // If only one type is available, return it
        if resultTypes.count == 1 {
            return resultTypes.first!
        }
        let processedPrompt = prompt.trimmingCharacters(in: .punctuationCharacters).lowercased()
        // Check cache (only for prompts that wouldn't trigger user dialog)
        if let cached = Self.cachedResult(for: processedPrompt) {
            return cached
        }
        let mlModelConfig = MLModelConfiguration()
        mlModelConfig.computeUnits = InferenceSettings.coreMLComputePreference.mlComputeUnits
        let bundledModelUrl: URL? = Bundle.main.url(
            forResource: "UserRequestClassifier",
            withExtension: "mlmodelc"
        )
        let customModelUrl: URL? = {
            guard let url = Settings.promptClassifierUrl else {
                return nil
            }
            let fileExists = FileManager.default.fileExists(atPath: url.path)
            return fileExists ? url : nil
        }()
        let classifierUrl: URL? = customModelUrl ?? bundledModelUrl
        guard let classifierUrl else {
            return .text
        }
        let compiledUrl: URL? = {
            if classifierUrl.pathExtension == "mlmodel" {
                return try? MLModel.compileModel(at: classifierUrl)
            }
            return classifierUrl
        }()
        guard let compiledUrl else {
            return .text
        }
        guard let promptClassifier: NLModel = try? NLModel(
            mlModel: MLModel(contentsOf: compiledUrl, configuration: mlModelConfig)
        ) else {
            return .text
        }
        // Run classifier
        let hypotheses: [String: Double] = promptClassifier.predictedLabelHypotheses(
            for: processedPrompt,
            maximumCount: ResultType.allCases.count
        )
        let textGenScore: Double = hypotheses[ResultType.text.rawValue] ?? 1.0
        let imageGenScore: Double = hypotheses[ResultType.image.rawValue] ?? 1.0
        // Get most likely result type
        let mostLikelyResultType: ResultType = textGenScore > imageGenScore ? .text : .image
        let similarThreshold = 0.3
        let scoreWasSimilar = abs(textGenScore - imageGenScore) < similarThreshold
        let promptWasTooShort = processedPrompt.count < 50 && mostLikelyResultType == .image
        if scoreWasSimilar || promptWasTooShort {
            // Prompt user; do not cache
            var wantedResultType: ResultType?
            _ = Dialogs.dichotomy(
                title: String(localized: "Response"),
                message: String(localized: "What do you want MLAI to respond with?"),
                option1: String(localized: "Text"),
                option2: String(localized: "Image")
            ) {
                wantedResultType = .text
            } ifOption2: {
                wantedResultType = .image
            }
            if let chosen = wantedResultType {
                TrainingDataCollector.recordUserChoice(
                    prompt: processedPrompt,
                    label: chosen.rawValue
                )
            }
            return wantedResultType ?? mostLikelyResultType
        }
        Self.Cache.store(processedPrompt, resultType: mostLikelyResultType)
        return mostLikelyResultType
    }

    @MainActor
    private static func cachedResult(for processedPrompt: String) -> ResultType? {
        Cache.retrieve(processedPrompt)
    }
	
	/// The expected result type of a prompt
	public enum ResultType: String, CaseIterable {
		
		init?(
			_ rawValue: String
		) {
			if let resultType: ResultType = Self.allCases.filter({ type in
				type.rawValue == rawValue
			}).first {
				self = resultType
			} else {
				return nil
			}
		}
		
		case text = "text-generation"
		case image = "image-generation"
		
		/// A `Bool` value indicating whether the result type is available
		@MainActor
		public var isAvailable: Bool {
			switch self {
				case .text:
					return true
				case .image:
					return ImagePlaygroundViewController.isAvailable
			}
		}
	}
    
}
