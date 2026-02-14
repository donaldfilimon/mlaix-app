//
//  InferenceSettingsTests.swift
//  MLAIXTests
//
//  Tests for InferenceSettings static properties and defaults.
//

import Foundation
import Testing
@testable import MLAIX

struct InferenceSettingsTests {

    @Test func testDefaultEndpoint() {
        #expect(InferenceSettings.defaultEndpoint == "https://router.huggingface.co/v1")
    }

    @Test func testMaxConsecutiveMalformedToolCalls() {
        #expect(InferenceSettings.maxConsecutiveMalformedToolCalls == 3)
    }

    @Test func testDefaultSystemPromptIsNonEmpty() {
        #expect(!InferenceSettings.defaultSystemPrompt.isEmpty)
        #expect(InferenceSettings.defaultSystemPrompt.contains("MLAI"))
    }

    @Test func testUseSourcesPromptIsNonEmpty() {
        #expect(!InferenceSettings.useSourcesPrompt.isEmpty)
    }

    @Test func testUseFunctionsPromptIsNonEmpty() {
        #expect(!InferenceSettings.useFunctionsPrompt.isEmpty)
    }

    @Test func testMetadataPromptContainsUserPlaceholder() {
        #expect(InferenceSettings.metadataPrompt.contains("user"))
    }

    // MARK: - Phase 2: CoreMLComputePreference

    @Test func testCoreMLComputePreferenceAllCases() {
        let cases = InferenceSettings.CoreMLComputePreference.allCases
        #expect(cases.count == 4)
        #expect(cases.contains(.cpuOnly))
        #expect(cases.contains(.cpuAndNeuralEngine))
        #expect(cases.contains(.cpuAndGPU))
        #expect(cases.contains(.all))
    }

    @Test func testCoreMLComputePreferenceRawValues() {
        #expect(InferenceSettings.CoreMLComputePreference.cpuOnly.rawValue == "cpuOnly")
        #expect(InferenceSettings.CoreMLComputePreference.cpuAndNeuralEngine.rawValue == "cpuAndNeuralEngine")
        #expect(InferenceSettings.CoreMLComputePreference.cpuAndGPU.rawValue == "cpuAndGPU")
        #expect(InferenceSettings.CoreMLComputePreference.all.rawValue == "all")
    }

    @Test func testCoreMLComputePreferenceInitFromRawValue() {
        #expect(InferenceSettings.CoreMLComputePreference(rawValue: "cpuOnly") == .cpuOnly)
        #expect(InferenceSettings.CoreMLComputePreference(rawValue: "cpuAndNeuralEngine") == .cpuAndNeuralEngine)
        #expect(InferenceSettings.CoreMLComputePreference(rawValue: "cpuAndGPU") == .cpuAndGPU)
        #expect(InferenceSettings.CoreMLComputePreference(rawValue: "all") == .all)
        #expect(InferenceSettings.CoreMLComputePreference(rawValue: "invalid") == nil)
    }

    @Test func testCoreMLComputePreferenceMLComputeUnits() {
        #expect(InferenceSettings.CoreMLComputePreference.cpuOnly.mlComputeUnits == .cpuOnly)
        #expect(InferenceSettings.CoreMLComputePreference.cpuAndNeuralEngine.mlComputeUnits == .cpuAndNeuralEngine)
        #expect(InferenceSettings.CoreMLComputePreference.cpuAndGPU.mlComputeUnits == .cpuAndGPU)
        #expect(InferenceSettings.CoreMLComputePreference.all.mlComputeUnits == .all)
    }

    @Test func testCoreMLComputePreferenceDisplayNames() {
        #expect(InferenceSettings.CoreMLComputePreference.cpuOnly.displayName == "CPU Only")
        #expect(InferenceSettings.CoreMLComputePreference.cpuAndNeuralEngine.displayName.contains("Neural Engine"))
        #expect(InferenceSettings.CoreMLComputePreference.cpuAndGPU.displayName.contains("GPU"))
        #expect(InferenceSettings.CoreMLComputePreference.all.displayName.contains("All"))
    }

    @Test func testCoreMLComputePreferenceDisplayNamesNonEmpty() {
        for pref in InferenceSettings.CoreMLComputePreference.allCases {
            #expect(!pref.displayName.isEmpty)
        }
    }

    // MARK: - setDefaults

    @Test func testSetDefaultsDoesNotCrash() {
        InferenceSettings.setDefaults()
        // If we reach here, no crash occurred
    }

    @Test func testSetDefaultsSetsSystemPrompt() {
        InferenceSettings.setDefaults()
        #expect(InferenceSettings.systemPrompt == InferenceSettings.defaultSystemPrompt)
    }

    // MARK: - unifiedMemorySize

    @Test func testUnifiedMemorySizeIsPositive() {
        #expect(InferenceSettings.unifiedMemorySize > 0)
    }

    @Test func testUnifiedMemorySizeIsReasonable() {
        // Modern Macs have at least 8 GB
        #expect(InferenceSettings.unifiedMemorySize >= 4)
        // Unlikely to exceed 256 GB on current hardware
        #expect(InferenceSettings.unifiedMemorySize <= 256)
    }

    // MARK: - shouldAutoEnableFlashAttention

    @Test @MainActor func testShouldAutoEnableFlashAttentionPropertyExists() {
        // Just verify the property is accessible and returns a boolean
        let result = InferenceSettings.shouldAutoEnableFlashAttention
        #expect(result == true || result == false)
    }

    // MARK: - lowUnifiedMemory

    @Test func testLowUnifiedMemoryConsistentWithSize() {
        let isLow = InferenceSettings.lowUnifiedMemory
        let size = InferenceSettings.unifiedMemorySize
        if size <= 12 {
            #expect(isLow == true)
        } else {
            #expect(isLow == false)
        }
    }
}
