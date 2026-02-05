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
    
    static func trainPromptClassifier(from datasetUrl: URL) async throws -> URL {
        #if canImport(CreateML)
        do {
            let classifier: MLTextClassifier
            if #available(macOS 13.0, *) {
                let dataFrame = try DataFrame(contentsOfCSVFile: datasetUrl)
                guard dataFrame.containsColumn("text"), dataFrame.containsColumn("label") else {
                    throw CoreMLTrainingError.invalidDataset
                }
                classifier = try MLTextClassifier(
                    trainingData: dataFrame,
                    textColumn: "text",
                    labelColumn: "label"
                )
            } else {
                let table = try MLDataTable(contentsOf: datasetUrl)
                let columns = Set(table.columnNames)
                guard columns.contains("text"), columns.contains("label") else {
                    throw CoreMLTrainingError.invalidDataset
                }
                classifier = try MLTextClassifier(
                    trainingData: table,
                    textColumn: "text",
                    labelColumn: "label"
                )
            }
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
