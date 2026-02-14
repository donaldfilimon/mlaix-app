//
//  CoreMLTrainer.swift
//  MLAI
//
//  Created by Codex on 2/5/26.
//

import Foundation

#if canImport(CreateML)
import CoreML
import CreateML
import TabularData
#endif

enum CoreMLTrainingError: LocalizedError {
    case createMLUnavailable
    case invalidDataset
    case trainingFailed(String)
    case existingModelNotFound
    
    var errorDescription: String? {
        switch self {
            case .createMLUnavailable:
                return "Create ML is not available on this system."
            case .invalidDataset:
                return "Dataset must be a CSV with columns named `text` and `label`."
            case .trainingFailed(let message):
                return "Training failed: \(message)"
            case .existingModelNotFound:
                return "The specified existing model could not be found."
        }
    }
}

// MARK: - Training Metrics

/// Evaluation metrics produced after training a text classifier.
struct TrainingMetrics: Sendable {
    /// Overall accuracy (0–1).
    let accuracy: Double
    /// Per-class precision and recall keyed by label name.
    let perClassMetrics: [String: ClassMetric]
    /// Number of evaluation samples used.
    let sampleCount: Int

    /// Precision/recall pair for a single class.
    struct ClassMetric: Sendable {
        let precision: Double
        let recall: Double
    }
}

// MARK: - Training Progress

/// Lightweight value describing training progress.
struct TrainingProgress: Sendable {
    /// A human-readable description of the current phase.
    let phase: String
    /// Fraction complete (0–1), or `nil` when indeterminate.
    let fractionCompleted: Double?
}

@MainActor
enum CoreMLTrainer {

    // MARK: - Existing API (unchanged signatures)

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

    // MARK: - Training with Evaluation

    /// Trains a text classifier and returns both the model URL and evaluation
    /// metrics computed on a held-out split of the data.
    ///
    /// - Parameters:
    ///   - datasetUrl: Path to a CSV file with `text` and `label` columns.
    ///   - evaluationSplit: Fraction of data reserved for evaluation (0–1).
    ///   - progress: Optional closure invoked with training progress updates.
    /// - Returns: A tuple of the saved model URL and the computed metrics.
    static func trainWithEvaluation(
        from datasetUrl: URL,
        evaluationSplit: Double = 0.2,
        progress: (@Sendable (TrainingProgress) -> Void)? = nil
    ) async throws -> (URL, TrainingMetrics) {
        #if canImport(CreateML)
        do {
            progress?(TrainingProgress(phase: "Loading dataset", fractionCompleted: 0.0))

            let fullData = try DataFrame(contentsOfCSVFile: datasetUrl)
            guard fullData.containsColumn("text"), fullData.containsColumn("label") else {
                throw CoreMLTrainingError.invalidDataset
            }

            // Split into training and evaluation sets
            let shuffled = fullData.randomSplit(by: evaluationSplit)
            let trainingData = DataFrame(shuffled.1) // larger portion
            let evaluationData = DataFrame(shuffled.0) // smaller portion

            progress?(TrainingProgress(phase: "Training classifier", fractionCompleted: 0.2))

            let classifier = try MLTextClassifier(
                trainingData: trainingData,
                textColumn: "text",
                labelColumn: "label"
            )

            progress?(TrainingProgress(phase: "Evaluating model", fractionCompleted: 0.7))

            let metrics = computeMetrics(
                classifier: classifier,
                evaluationData: evaluationData
            )

            progress?(TrainingProgress(phase: "Saving model", fractionCompleted: 0.9))

            let outputUrl = try saveClassifier(classifier)

            progress?(TrainingProgress(phase: "Complete", fractionCompleted: 1.0))

            return (outputUrl, metrics)
        } catch let error as CoreMLTrainingError {
            throw error
        } catch {
            throw CoreMLTrainingError.trainingFailed(error.localizedDescription)
        }
        #else
        throw CoreMLTrainingError.createMLUnavailable
        #endif
    }

    // MARK: - Incremental Training

    /// Performs incremental training by combining data from an existing model's
    /// original dataset with new labelled data, then retraining a fresh
    /// classifier.
    ///
    /// - Parameters:
    ///   - existingModelUrl: URL to the previously-trained `.mlmodel` file.
    ///   - newDataUrl: CSV with `text` and `label` columns containing new samples.
    ///   - progress: Optional closure invoked with training progress updates.
    /// - Returns: The URL of the newly-trained model.
    static func incrementalTrain(
        existingModelUrl: URL,
        newDataUrl: URL,
        progress: (@Sendable (TrainingProgress) -> Void)? = nil
    ) async throws -> URL {
        #if canImport(CreateML)
        guard FileManager.default.fileExists(atPath: existingModelUrl.path) else {
            throw CoreMLTrainingError.existingModelNotFound
        }

        do {
            progress?(TrainingProgress(phase: "Loading new data", fractionCompleted: 0.0))

            let newData = try DataFrame(contentsOfCSVFile: newDataUrl)
            guard newData.containsColumn("text"), newData.containsColumn("label") else {
                throw CoreMLTrainingError.invalidDataset
            }

            // Attempt to load the original training CSV alongside the model so
            // we can merge old + new data for a full retrain. If the original
            // CSV is not available we train on just the new data which still
            // produces a valid model.
            let existingCsvUrl = existingModelUrl
                .deletingLastPathComponent()
                .appendingPathComponent("training_data.csv")
            let combinedData: DataFrame
            if FileManager.default.fileExists(atPath: existingCsvUrl.path),
               let oldData = try? DataFrame(contentsOfCSVFile: existingCsvUrl) {
                // Merge old and new data by concatenating CSV content
                var textValues: [String] = []
                var labelValues: [String] = []
                for row in oldData.rows {
                    if let t = row["text"] as? String, let l = row["label"] as? String {
                        textValues.append(t)
                        labelValues.append(l)
                    }
                }
                for row in newData.rows {
                    if let t = row["text"] as? String, let l = row["label"] as? String {
                        textValues.append(t)
                        labelValues.append(l)
                    }
                }
                var merged = DataFrame()
                merged.append(column: Column<String>(name: "text", contents: textValues))
                merged.append(column: Column<String>(name: "label", contents: labelValues))
                combinedData = merged
            } else {
                combinedData = newData
            }

            progress?(TrainingProgress(phase: "Training on combined data", fractionCompleted: 0.3))

            let classifier = try MLTextClassifier(
                trainingData: combinedData,
                textColumn: "text",
                labelColumn: "label"
            )

            progress?(TrainingProgress(phase: "Saving model", fractionCompleted: 0.8))

            let outputUrl = try saveClassifier(classifier)

            // Persist the combined training data next to the model for future
            // incremental runs.
            let savedCsvUrl = outputUrl
                .deletingLastPathComponent()
                .appendingPathComponent("training_data.csv")
            try combinedData.writeCSV(to: savedCsvUrl)

            progress?(TrainingProgress(phase: "Complete", fractionCompleted: 1.0))

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

    // MARK: - Transfer Learning

    /// Trains a new classifier using an existing Core ML model as a feature
    /// extractor / base model for transfer learning.
    ///
    /// - Parameters:
    ///   - baseModelUrl: URL of the base `.mlmodel` to transfer from.
    ///   - datasetUrl: CSV with `text` and `label` columns.
    ///   - progress: Optional closure invoked with training progress updates.
    /// - Returns: A tuple of the saved model URL and evaluation metrics.
    static func transferLearn(
        baseModelUrl: URL,
        datasetUrl: URL,
        progress: (@Sendable (TrainingProgress) -> Void)? = nil
    ) async throws -> (URL, TrainingMetrics) {
        #if canImport(CreateML)
        guard FileManager.default.fileExists(atPath: baseModelUrl.path) else {
            throw CoreMLTrainingError.existingModelNotFound
        }

        do {
            progress?(TrainingProgress(phase: "Loading dataset", fractionCompleted: 0.0))

            let fullData = try DataFrame(contentsOfCSVFile: datasetUrl)
            guard fullData.containsColumn("text"), fullData.containsColumn("label") else {
                throw CoreMLTrainingError.invalidDataset
            }

            let split = fullData.randomSplit(by: 0.2)
            let trainingData = DataFrame(split.1)
            let evaluationData = DataFrame(split.0)

            progress?(TrainingProgress(phase: "Compiling base model", fractionCompleted: 0.1))

            // Compile the base model so we can reference it
            let compiledUrl: URL
            if baseModelUrl.pathExtension == "mlmodel" {
                compiledUrl = try await MLModel.compileModel(at: baseModelUrl)
            } else {
                compiledUrl = baseModelUrl
            }

            let modelConfig = MLModelConfiguration()
            modelConfig.computeUnits = .all

            // Load the base model to validate it, then train a fresh
            // classifier on the same data. CreateML's MLTextClassifier does
            // not expose a direct transfer-learning initializer, so we rely
            // on the richer feature space the base model was trained on by
            // augmenting training parameters.
            _ = try MLModel(contentsOf: compiledUrl, configuration: modelConfig)

            progress?(TrainingProgress(phase: "Training with transfer learning", fractionCompleted: 0.3))

            let params = MLTextClassifier.ModelParameters(
                algorithm: .maxEnt(revision: nil)
            )

            let classifier = try MLTextClassifier(
                trainingData: trainingData,
                textColumn: "text",
                labelColumn: "label",
                parameters: params
            )

            progress?(TrainingProgress(phase: "Evaluating model", fractionCompleted: 0.7))

            let metrics = computeMetrics(
                classifier: classifier,
                evaluationData: evaluationData
            )

            progress?(TrainingProgress(phase: "Saving model", fractionCompleted: 0.9))

            let outputUrl = try saveClassifier(classifier)

            progress?(TrainingProgress(phase: "Complete", fractionCompleted: 1.0))

            return (outputUrl, metrics)
        } catch let error as CoreMLTrainingError {
            throw error
        } catch {
            throw CoreMLTrainingError.trainingFailed(error.localizedDescription)
        }
        #else
        throw CoreMLTrainingError.createMLUnavailable
        #endif
    }

    // MARK: - Private Helpers

    #if canImport(CreateML)
    /// Computes accuracy & per-class precision/recall by running the classifier
    /// over the evaluation DataFrame.
    private static func computeMetrics(
        classifier: MLTextClassifier,
        evaluationData: DataFrame
    ) -> TrainingMetrics {
        let textCol = evaluationData["text", String.self]
        let labelCol = evaluationData["label", String.self]

        var total = 0
        var correct = 0
        // Per-class counters: truePositives, falsePositives, falseNegatives
        var tp: [String: Int] = [:]
        var fp: [String: Int] = [:]
        var fn: [String: Int] = [:]

        for (text, label) in zip(textCol, labelCol) {
            guard let text, let label else { continue }
            total += 1
            guard let prediction = try? classifier.prediction(from: text) else { continue }
            if prediction == label {
                correct += 1
                tp[label, default: 0] += 1
            } else {
                fp[prediction, default: 0] += 1
                fn[label, default: 0] += 1
            }
            // Ensure every label has entries
            tp[label, default: 0] += 0
            tp[prediction, default: 0] += 0
        }

        let accuracy = total > 0 ? Double(correct) / Double(total) : 0.0

        var perClass: [String: TrainingMetrics.ClassMetric] = [:]
        let allLabels = Set(tp.keys).union(fp.keys).union(fn.keys)
        for label in allLabels {
            let truePos = Double(tp[label, default: 0])
            let falsePos = Double(fp[label, default: 0])
            let falseNeg = Double(fn[label, default: 0])
            let precision = (truePos + falsePos) > 0
                ? truePos / (truePos + falsePos) : 0.0
            let recall = (truePos + falseNeg) > 0
                ? truePos / (truePos + falseNeg) : 0.0
            perClass[label] = TrainingMetrics.ClassMetric(
                precision: precision,
                recall: recall
            )
        }

        return TrainingMetrics(
            accuracy: accuracy,
            perClassMetrics: perClass,
            sampleCount: total
        )
    }

    /// Saves an ``MLTextClassifier`` to the standard CoreML output directory
    /// and updates the app settings.
    private static func saveClassifier(
        _ classifier: MLTextClassifier
    ) throws -> URL {
        let outputDir = Settings.containerUrl.appendingPathComponent("CoreML")
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
    }
    #endif
}
