//
//  SettingsModelSupportTests.swift
//  MLAITests
//
//  Tests for model URL support helpers and default remote endpoint.
//

import Foundation
import Testing
@testable import MLAIX

struct SettingsModelSupportTests {

    @Test func testGGUFModelURLDetection() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let ggufUrl = tempDir.appendingPathComponent("test.gguf")
        try "".write(to: ggufUrl, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: ggufUrl) }

        #expect(Settings.isGGUFModelURL(ggufUrl) == true)
        #expect(Settings.isSupportedModelURL(ggufUrl) == true)

        let txtUrl = tempDir.appendingPathComponent("test.txt")
        try "".write(to: txtUrl, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: txtUrl) }

        #expect(Settings.isGGUFModelURL(txtUrl) == false)
    }

    @Test func testMLXModelFileDetection() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let mlxUrl = tempDir.appendingPathComponent("test.mlx")
        try "".write(to: mlxUrl, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: mlxUrl) }

        #expect(Settings.isMLXModelURL(mlxUrl) == true)
        #expect(Settings.isSupportedModelURL(mlxUrl) == true)
    }

    @Test func testMLXModelDirectoryDetection() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let modelDir = tempDir.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: modelDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: modelDir) }

        let configUrl = modelDir.appendingPathComponent("config.json")
        let tokenizerUrl = modelDir.appendingPathComponent("tokenizer.json")
        let weightsUrl = modelDir.appendingPathComponent("weights.safetensors")
        try "{}".write(to: configUrl, atomically: true, encoding: .utf8)
        try "{}".write(to: tokenizerUrl, atomically: true, encoding: .utf8)
        try "".write(to: weightsUrl, atomically: true, encoding: .utf8)

        #expect(Settings.isMLXModelURL(modelDir) == true)
        #expect(Settings.isSupportedModelURL(modelDir) == true)
    }

    @Test func testMLXModelDirectoryMissingFiles() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let modelDir = tempDir.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: modelDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: modelDir) }

        let configUrl = modelDir.appendingPathComponent("config.json")
        try "{}".write(to: configUrl, atomically: true, encoding: .utf8)

        #expect(Settings.isMLXModelURL(modelDir) == false)
    }

    @Test func testDefaultRemoteEndpointMatchesProvider() {
        #expect(
            InferenceSettings.defaultEndpoint == Provider.huggingFaceRouter.endpointUrl.absoluteString
        )
    }

    @Test func testDeepResearchDepthDefaults() {
        let fast = DeepResearchDepth.fast.defaults
        #expect(fast.minSources == 4)
        #expect(fast.maxSources == 6)
        #expect(fast.minToolCalls == 4)
        #expect(fast.maxSections == 4)

        let balanced = DeepResearchDepth.balanced.defaults
        #expect(balanced.minSources == 7)
        #expect(balanced.maxSources == 10)

        let thorough = DeepResearchDepth.thorough.defaults
        #expect(thorough.minSources == 10)
        #expect(thorough.maxSections == 8)
    }

    @Test func testDeepResearchDepthRawValues() {
        #expect(DeepResearchDepth.fast.rawValue == "fast")
        #expect(DeepResearchDepth.balanced.rawValue == "balanced")
        #expect(DeepResearchDepth.thorough.rawValue == "thorough")
    }

    @Test func testRetrievalSettingsSearchProvider() {
        #expect(RetrievalSettings.SearchProvider.duckDuckGo.rawValue == 0)
        #expect(RetrievalSettings.SearchProvider.tavily.rawValue == 1)
        #expect(RetrievalSettings.SearchProvider.google.rawValue == 2)
        #expect(RetrievalSettings.SearchProvider.allCases.count == 3)
    }
}
