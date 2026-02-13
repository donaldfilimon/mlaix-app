//
//  CoreMLTrainerTests.swift
//  MLAIXTests
//
//  Tests for CoreMLTrainer error types and validation.
//

import Foundation
import Testing
@testable import MLAIX

struct CoreMLTrainerTests {

    @Test func testCoreMLTrainingErrorDescriptions() {
        let createML = CoreMLTrainingError.createMLUnavailable
        #expect(createML.errorDescription?.contains("Create ML") == true)

        let invalid = CoreMLTrainingError.invalidDataset
        #expect(invalid.errorDescription?.contains("CSV") == true)
        #expect(invalid.errorDescription?.contains("text") == true)
        #expect(invalid.errorDescription?.contains("label") == true)

        let failed = CoreMLTrainingError.trainingFailed("custom message")
        #expect(failed.errorDescription?.contains("custom message") == true)
    }

    @Test func testCoreMLTrainingErrorLocalizedError() {
        let error = CoreMLTrainingError.createMLUnavailable
        #expect(error as Error is LocalizedError)
    }

    // MARK: - Phase 2: existingModelNotFound

    @Test func testExistingModelNotFoundDescription() {
        let error = CoreMLTrainingError.existingModelNotFound
        #expect(error.errorDescription?.contains("existing model") == true)
        #expect(error.errorDescription?.contains("could not be found") == true)
    }

    @Test func testAllErrorCasesHaveDescriptions() {
        let errors: [CoreMLTrainingError] = [
            .createMLUnavailable,
            .invalidDataset,
            .trainingFailed("test"),
            .existingModelNotFound
        ]
        for error in errors {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }

    // MARK: - TrainingMetrics

    @Test func testTrainingMetricsInit() {
        let metrics = TrainingMetrics(
            accuracy: 0.95,
            perClassMetrics: [
                "positive": TrainingMetrics.ClassMetric(precision: 0.9, recall: 0.85),
                "negative": TrainingMetrics.ClassMetric(precision: 0.88, recall: 0.92)
            ],
            sampleCount: 100
        )
        #expect(metrics.accuracy == 0.95)
        #expect(metrics.sampleCount == 100)
        #expect(metrics.perClassMetrics.count == 2)
    }

    @Test func testTrainingMetricsAccuracyRange() {
        let metrics = TrainingMetrics(
            accuracy: 0.5,
            perClassMetrics: [:],
            sampleCount: 10
        )
        #expect(metrics.accuracy >= 0.0)
        #expect(metrics.accuracy <= 1.0)
    }

    @Test func testTrainingMetricsEmptyPerClass() {
        let metrics = TrainingMetrics(
            accuracy: 1.0,
            perClassMetrics: [:],
            sampleCount: 0
        )
        #expect(metrics.perClassMetrics.isEmpty)
        #expect(metrics.sampleCount == 0)
    }

    // MARK: - ClassMetric

    @Test func testClassMetricInit() {
        let metric = TrainingMetrics.ClassMetric(precision: 0.85, recall: 0.90)
        #expect(metric.precision == 0.85)
        #expect(metric.recall == 0.90)
    }

    @Test func testClassMetricPerfectScores() {
        let metric = TrainingMetrics.ClassMetric(precision: 1.0, recall: 1.0)
        #expect(metric.precision == 1.0)
        #expect(metric.recall == 1.0)
    }

    @Test func testClassMetricZeroScores() {
        let metric = TrainingMetrics.ClassMetric(precision: 0.0, recall: 0.0)
        #expect(metric.precision == 0.0)
        #expect(metric.recall == 0.0)
    }

    // MARK: - TrainingProgress

    @Test func testTrainingProgressInit() {
        let progress = TrainingProgress(phase: "Loading", fractionCompleted: 0.5)
        #expect(progress.phase == "Loading")
        #expect(progress.fractionCompleted == 0.5)
    }

    @Test func testTrainingProgressNilFraction() {
        let progress = TrainingProgress(phase: "Indeterminate", fractionCompleted: nil)
        #expect(progress.phase == "Indeterminate")
        #expect(progress.fractionCompleted == nil)
    }

    @Test func testTrainingProgressComplete() {
        let progress = TrainingProgress(phase: "Complete", fractionCompleted: 1.0)
        #expect(progress.phase == "Complete")
        #expect(progress.fractionCompleted == 1.0)
    }

    @Test func testTrainingProgressIsSendable() {
        let progress = TrainingProgress(phase: "Sending", fractionCompleted: 0.3)
        // Verify Sendable conformance by passing across isolation boundary
        let sendableCheck: @Sendable () -> String = { progress.phase }
        #expect(sendableCheck() == "Sending")
    }

    @Test func testTrainingMetricsIsSendable() {
        let metrics = TrainingMetrics(
            accuracy: 0.8,
            perClassMetrics: [:],
            sampleCount: 5
        )
        let sendableCheck: @Sendable () -> Double = { metrics.accuracy }
        #expect(sendableCheck() == 0.8)
    }
}
