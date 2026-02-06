//
//  CoreMLTrainer.swift
//  MLAI
//
//  Created by Codex on 2/5/26.
//

import Foundation

#if canImport(CreateML)
import CreateML
import TabularData
#endif

enum CoreMLTrainingError: LocalizedError {
    case createMLUnavailable
    case invalidDataset
    case trainingFailed(String)
    
    var errorDescription: String? {
        switch self {
            case .createMLUnavailable:
                return "Create ML is not available on this system."
            case .invalidDataset:
                return "Dataset must be a CSV with columns named `text` and `label`."
            case .trainingFailed(let message):
                return "Training failed: \(message)"
        }
    }
}

@MainActor
enum CoreMLTrainer {

    /// Trains from the collected self-learning data (user choices + exported conversations).
    /// Returns the model URL if training succeeds and samples exist.
    static func trainFromCollectedData() async throws -> URL? {
        let url = TrainingDataCollector.trainingDataUrl
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        guard TrainingDataCollector.collectedSampleCount >= 10 else {
            throw CoreMLTrainingError.trainingFailed("Need at least 10 samples. Current: \(TrainingDataCollector.collectedSampleCount)")
        }
        return try await trainPromptClassifier(from: url)
    }

    static func trainPromptClassifier(from datasetUrl: URL) async throws -> URL {
        #if canImport(CreateML)
        do {
            let dataFrame = try DataFrame(contentsOfCSVFile: datasetUrl)
            guard dataFrame.containsColumn("text"), dataFrame.containsColumn("label") else {
                throw CoreMLTrainingError.invalidDataset
            }
            let classifier = try MLTextClassifier(
                trainingData: dataFrame,
                textColumn: "text",
                labelColumn: "label"
            )
            let outputDir = Settings.containerUrl.appendingPathComponent(
                "CoreML"
            )
            if !FileManager.default.fileExists(atPath: outputDir.path) {
                try FileManager.default.createDirectory(
                    at: outputDir,
                    withIntermediateDirectories: true
                )
            }
            let outputUrl = outputDir.appendingPathComponent(
                "UserRequestClassifier.mlmodel"
            )
            try classifier.write(to: outputUrl)
            Settings.promptClassifierUrl = outputUrl
            return outputUrl
        } catch let error as CoreMLTrainingError {
            throw error
        } catch {
            throw CoreMLTrainingError.trainingFailed(error.localizedDescription)
        }
        #else
        throw CoreMLTrainingError.createMLUnavailable
        #endif
    }
}
