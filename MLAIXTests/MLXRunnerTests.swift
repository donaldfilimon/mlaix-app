//
//  MLXRunnerTests.swift
//  MLAIXTests
//
//  Tests for MLXRunner types, error descriptions, and availability.
//

import Foundation
import Testing
@testable import MLAIX

@Suite("MLXRunnerTests")
struct MLXRunnerTests {

    // MARK: - MLXError descriptions

    @Test func errorPythonUnavailableDescription() {
        let error = MLXRunner.MLXError.pythonUnavailable
        #expect(error.errorDescription?.contains("Python") == true)
    }

    @Test func errorInvalidResponseDescription() {
        let error = MLXRunner.MLXError.invalidResponse
        #expect(error.errorDescription?.contains("valid response") == true)
    }

    @Test func errorGenerationFailedDescription() {
        let error = MLXRunner.MLXError.generationFailed("timeout occurred")
        #expect(error.errorDescription?.contains("timeout occurred") == true)
        #expect(error.errorDescription?.contains("generation failed") == true)
    }

    @Test func errorModelLoadFailedDescription() {
        let error = MLXRunner.MLXError.modelLoadFailed("file not found")
        #expect(error.errorDescription?.contains("file not found") == true)
        #expect(error.errorDescription?.contains("Failed to load") == true)
    }

    @Test func errorConformsToLocalizedError() {
        let error: any Error = MLXRunner.MLXError.invalidResponse
        #expect(error is LocalizedError)
    }

    // MARK: - Availability struct

    @Test func availabilityStructFieldAccess() {
        let avail = MLXRunner.Availability(
            pythonAvailable: false,
            mlxAvailable: true,
            mlxVersion: "native",
            nativeAvailable: true
        )
        #expect(avail.pythonAvailable == false)
        #expect(avail.mlxAvailable == true)
        #expect(avail.mlxVersion == "native")
        #expect(avail.nativeAvailable == true)
    }

    @Test func availabilityNilVersion() {
        let avail = MLXRunner.Availability(
            pythonAvailable: false,
            mlxAvailable: false,
            mlxVersion: nil,
            nativeAvailable: false
        )
        #expect(avail.mlxVersion == nil)
    }

    // MARK: - checkAvailability

    @Test func checkAvailabilityReturnsValid() async {
        let avail = await MLXRunner.checkAvailability()
        // Native MLX should always be available on Apple Silicon builds
        #expect(avail.nativeAvailable == true)
        #expect(avail.mlxAvailable == true)
        #expect(avail.pythonAvailable == false)
        #expect(avail.mlxVersion == "native")
    }

    // MARK: - Message Codable roundtrip

    @Test func messageCodableRoundtrip() throws {
        let message = MLXRunner.Message(role: "user", content: "Hello")
        let data = try JSONEncoder().encode(message)
        let decoded = try JSONDecoder().decode(MLXRunner.Message.self, from: data)
        #expect(decoded.role == "user")
        #expect(decoded.content == "Hello")
    }

    @Test func messageWithSystemRole() throws {
        let message = MLXRunner.Message(role: "system", content: "You are helpful")
        let data = try JSONEncoder().encode(message)
        let decoded = try JSONDecoder().decode(MLXRunner.Message.self, from: data)
        #expect(decoded.role == "system")
        #expect(decoded.content == "You are helpful")
    }

    // MARK: - Request Codable roundtrip

    @Test func requestCodableRoundtrip() throws {
        let request = MLXRunner.Request(
            modelPath: "/tmp/model",
            messages: [MLXRunner.Message(role: "user", content: "Hi")],
            maxTokens: 512,
            temperature: 0.7,
            topP: 0.9
        )
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(MLXRunner.Request.self, from: data)
        #expect(decoded.modelPath == "/tmp/model")
        #expect(decoded.messages.count == 1)
        #expect(decoded.messages.first?.role == "user")
        #expect(decoded.maxTokens == 512)
        #expect(decoded.temperature == 0.7)
        #expect(decoded.topP == 0.9)
    }

    @Test func requestCodingKeysSnakeCase() throws {
        let request = MLXRunner.Request(
            modelPath: "/path",
            messages: [],
            maxTokens: 100,
            temperature: 0.5,
            topP: 0.8
        )
        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        // Verify snake_case keys
        #expect(json?["model_path"] != nil)
        #expect(json?["max_tokens"] != nil)
        #expect(json?["top_p"] != nil)
    }

    // MARK: - Response Codable roundtrip

    @Test func responseCodableRoundtrip() throws {
        let response = MLXRunner.Response(
            text: "Hello world",
            promptTokens: 10,
            completionTokens: 5,
            error: nil
        )
        let data = try JSONEncoder().encode(response)
        let decoded = try JSONDecoder().decode(MLXRunner.Response.self, from: data)
        #expect(decoded.text == "Hello world")
        #expect(decoded.promptTokens == 10)
        #expect(decoded.completionTokens == 5)
        #expect(decoded.error == nil)
    }

    @Test func responseWithError() throws {
        let response = MLXRunner.Response(
            text: nil,
            promptTokens: nil,
            completionTokens: nil,
            error: "something went wrong"
        )
        let data = try JSONEncoder().encode(response)
        let decoded = try JSONDecoder().decode(MLXRunner.Response.self, from: data)
        #expect(decoded.text == nil)
        #expect(decoded.error == "something went wrong")
    }

    @Test func responseCodingKeysSnakeCase() throws {
        let response = MLXRunner.Response(
            text: "ok",
            promptTokens: 1,
            completionTokens: 2,
            error: nil
        )
        let data = try JSONEncoder().encode(response)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json?["prompt_tokens"] != nil)
        #expect(json?["completion_tokens"] != nil)
    }

    // MARK: - clearModelCache

    @Test func clearModelCacheDoesNotCrash() async {
        await MLXRunner.clearModelCache()
        // Just verify it completes without error
    }
}
