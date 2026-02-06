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
}
