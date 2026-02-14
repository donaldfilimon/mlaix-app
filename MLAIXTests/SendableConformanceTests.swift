//
//  SendableConformanceTests.swift
//  MLAITests
//
//  Tests verifying Sendable conformance for value types.
//

import Foundation
import Testing
@testable import MLAIX

// MARK: - EvaluationDetails Sendable Tests

struct EvaluationDetailsSendableTests {

    @Test func testChunkStateSendableAcrossTasks() async {
        let results = await withTaskGroup(
            of: EvaluationDetails.Chunk.State.self,
            returning: [EvaluationDetails.Chunk.State].self
        ) { group in
            for _ in 0..<50 {
                group.addTask {
                    .drivingAiProb
                }
            }
            var out: [EvaluationDetails.Chunk.State] = []
            for await r in group { out.append(r) }
            return out
        }
        #expect(results.allSatisfy { $0 == .drivingAiProb })
    }

    @Test func testChunkSendableAcrossTasks() async {
        let chunk = EvaluationDetails.Chunk(text: "hello", state: .normal)
        let results = await withTaskGroup(of: String.self, returning: [String].self) { group in
            for _ in 0..<50 {
                group.addTask {
                    chunk.text
                }
            }
            var out: [String] = []
            for await r in group { out.append(r) }
            return out
        }
        #expect(results.allSatisfy { $0 == "hello" })
    }

    @Test func testEvaluationDetailsSendableAcrossTasks() async {
        let details = EvaluationDetails(chunks: [
            .init(text: "a", state: .normal),
            .init(text: "b", state: .drivingHumanProb),
        ])
        let results = await withTaskGroup(of: Int.self, returning: [Int].self) { group in
            for _ in 0..<50 {
                group.addTask {
                    details.chunks.count
                }
            }
            var out: [Int] = []
            for await r in group { out.append(r) }
            return out
        }
        #expect(results.allSatisfy { $0 == 2 })
    }

    @Test func testChunkStateAllCases() {
        let cases = EvaluationDetails.Chunk.State.allCases
        #expect(cases.count == 3)
        #expect(cases.contains(.normal))
        #expect(cases.contains(.drivingAiProb))
        #expect(cases.contains(.drivingHumanProb))
    }
}

// MARK: - ChatParameters Sendable Tests

struct ChatParametersSendableTests {

    @Test func testParamKeySendableAcrossTasks() async {
        let results = await withTaskGroup(of: String.self, returning: [String].self) { group in
            for _ in 0..<50 {
                group.addTask {
                    ChatParameters.ParamKey.model.rawValue
                }
            }
            var out: [String] = []
            for await r in group { out.append(r) }
            return out
        }
        #expect(results.allSatisfy { $0 == "model" })
    }

    @Test func testParamKeyAllCases() {
        let cases = ChatParameters.ParamKey.allCases
        #expect(cases.count == 8)
        #expect(cases.contains(.model))
        #expect(cases.contains(.reasoning))
    }

    @Test func testStreamOptionsSendableAcrossTasks() async {
        let opts = ChatParameters.StreamOptions()
        let results = await withTaskGroup(of: Bool.self, returning: [Bool].self) { group in
            for _ in 0..<50 {
                group.addTask {
                    opts.include_usage
                }
            }
            var out: [Bool] = []
            for await r in group { out.append(r) }
            return out
        }
        #expect(results.allSatisfy { $0 == true })
    }

    @Test func testReasoningOptionsSendable() async {
        let opts = ChatParameters.ReasoningOptions(max_tokens: 8000)
        let results = await withTaskGroup(of: Int.self, returning: [Int].self) { group in
            for _ in 0..<50 {
                group.addTask {
                    opts.max_tokens
                }
            }
            var out: [Int] = []
            for await r in group { out.append(r) }
            return out
        }
        #expect(results.allSatisfy { $0 == 8000 })
    }

    @Test func testReasoningOptionsCodableRoundtrip() throws {
        let original = ChatParameters.ReasoningOptions(max_tokens: 4096)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ChatParameters.ReasoningOptions.self, from: data)
        #expect(decoded.max_tokens == 4096)
    }
}

// MARK: - ModelFamily Sendable Tests

struct ModelFamilySendableTests {

    @Test func testModelFamilySendableAcrossTasks() async {
        let family = ModelFamily(
            name: "TestFamily",
            family: .llama3,
            models: []
        )
        let results = await withTaskGroup(of: String.self, returning: [String].self) { group in
            for _ in 0..<50 {
                group.addTask {
                    family.name
                }
            }
            var out: [String] = []
            for await r in group { out.append(r) }
            return out
        }
        #expect(results.allSatisfy { $0 == "TestFamily" })
    }

    @Test func testModelFamilyIdIsName() {
        let family = ModelFamily(
            name: "Qwen",
            family: .qwen2,
            models: []
        )
        #expect(family.id == "Qwen")
    }
}
