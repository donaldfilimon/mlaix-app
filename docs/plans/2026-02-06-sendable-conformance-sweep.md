# Sendable Conformance Sweep — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add `Sendable` conformance to all types that cross concurrency boundaries (or may in the future), and add tests to verify thread-safety, bringing the codebase closer to full Swift 6 strict concurrency compliance with zero new warnings.

**Architecture:** Each target type is a pure-value struct or enum with no reference-type properties. We add `: Sendable` to the declaration, build to confirm no warnings, then write a concurrent test that reads/creates instances from multiple tasks. `ModelFamily` depends on an external `HuggingFaceModel` that is NOT Sendable, so it gets `@unchecked Sendable` with a code comment.

**Tech Stack:** Swift 6.2, Swift Testing (`@Test`, `#expect`), SwiftPM (`swift build`, `swift test`)

---

### Task 1: Add Sendable to LogLevel and OSLogLevel

**Files:**
- Modify: `MLAIX/Types/LogLevel.swift:5` and `:32`
- Test: `MLAIXTests/SendableConformanceTests.swift` (create)

**Step 1: Write the failing test**

Create `MLAIXTests/SendableConformanceTests.swift`:

```swift
//
//  SendableConformanceTests.swift
//  MLAITests
//
//  Tests verifying Sendable conformance for value types.
//

import Foundation
import Testing
@testable import MLAI

// MARK: - LogLevel Sendable Tests

struct LogLevelSendableTests {

    @Test func testLogLevelSendableAcrossTasks() async {
        let level = LogLevel.warning
        let results = await withTaskGroup(of: Bool.self, returning: [Bool].self) { group in
            for _ in 0..<50 {
                group.addTask {
                    level.allows(osLogLevel: .error)
                }
            }
            var out: [Bool] = []
            for await r in group { out.append(r) }
            return out
        }
        #expect(results.allSatisfy { $0 == true })
    }

    @Test func testOSLogLevelSendableAcrossTasks() async {
        let results = await withTaskGroup(of: Int.self, returning: [Int].self) { group in
            for _ in 0..<50 {
                group.addTask {
                    OSLogLevel.error.rawValue
                }
            }
            var out: [Int] = []
            for await r in group { out.append(r) }
            return out
        }
        let unique = Set(results)
        #expect(unique.count == 1)
        #expect(unique.first == 6)
    }

    @Test func testLogLevelAllowsLevels() {
        #expect(LogLevel.debug.allows(osLogLevel: .trace) == true)
        #expect(LogLevel.error.allows(osLogLevel: .info) == false)
        #expect(LogLevel.none.allows(osLogLevel: .fault) == true)
    }

    @Test func testOSLogLevelComparable() {
        #expect(OSLogLevel.debug < OSLogLevel.error)
        #expect(OSLogLevel.fault > OSLogLevel.warning)
        #expect(OSLogLevel.info == OSLogLevel.info)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter SendableConformanceTests 2>&1 | tail -15`
Expected: Compiler warning — `LogLevel` / `OSLogLevel` cannot satisfy `Sendable` requirement in task closure (or test passes with implicit Sendable due to value type, either way proceed).

**Step 3: Add Sendable conformance**

In `MLAIX/Types/LogLevel.swift`, change line 5:
```swift
public enum LogLevel: Sendable {
```

Change line 32:
```swift
public enum OSLogLevel: Int, Comparable, Sendable {
```

**Step 4: Build and run tests**

Run: `swift build 2>&1 | tail -3 && swift test --filter SendableConformanceTests 2>&1 | tail -10`
Expected: Build with 0 warnings, all 4 tests pass.

**Step 5: Commit**

```bash
git add MLAIX/Types/LogLevel.swift MLAIXTests/SendableConformanceTests.swift
git commit -m "feat: add Sendable to LogLevel and OSLogLevel with tests"
```

---

### Task 2: Add Sendable to Notifications enum

**Files:**
- Modify: `MLAIX/Types/Notifications.swift:10`
- Test: `MLAIXTests/SendableConformanceTests.swift` (append)

**Step 1: Write the failing test**

Append to `MLAIXTests/SendableConformanceTests.swift`:

```swift
// MARK: - Notifications Sendable Tests

struct NotificationsSendableTests {

    @Test func testNotificationsSendableAcrossTasks() async {
        let results = await withTaskGroup(of: String.self, returning: [String].self) { group in
            for _ in 0..<50 {
                group.addTask {
                    Notifications.newConversation.rawValue
                }
            }
            var out: [String] = []
            for await r in group { out.append(r) }
            return out
        }
        let unique = Set(results)
        #expect(unique.count == 1)
        #expect(unique.first == "newConversation")
    }

    @Test func testNotificationNameProperty() {
        let note = Notifications.systemPromptChanged
        #expect(note.name == Notification.Name("systemPromptChanged"))
    }

    @Test func testAllNotificationCases() {
        let cases: [Notifications] = [
            .systemPromptChanged,
            .changedInferenceConfig,
            .didCommandSelectExpert,
            .newConversation,
            .switchToConversation,
        ]
        #expect(cases.count == 5)
    }
}
```

**Step 2: Run test to verify it compiles but confirm direction**

Run: `swift test --filter NotificationsSendableTests 2>&1 | tail -10`

**Step 3: Add Sendable conformance**

In `MLAIX/Types/Notifications.swift`, change line 10:
```swift
public enum Notifications: String, NotificationName, Sendable {
```

**Step 4: Build and run tests**

Run: `swift build 2>&1 | tail -3 && swift test --filter NotificationsSendableTests 2>&1 | tail -10`
Expected: 0 warnings, 3 tests pass.

**Step 5: Commit**

```bash
git add MLAIX/Types/Notifications.swift MLAIXTests/SendableConformanceTests.swift
git commit -m "feat: add Sendable to Notifications enum with tests"
```

---

### Task 3: Add Sendable to EvaluationDetails, Chunk, and State

**Files:**
- Modify: `MLAIX/Types/EvaluationDetails.swift:11`, `:15`, `:22`
- Test: `MLAIXTests/SendableConformanceTests.swift` (append)

**Step 1: Write the failing test**

Append to `MLAIXTests/SendableConformanceTests.swift`:

```swift
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
```

**Step 2: Run test to verify direction**

Run: `swift test --filter EvaluationDetailsSendableTests 2>&1 | tail -10`

**Step 3: Add Sendable conformance**

In `MLAIX/Types/EvaluationDetails.swift`:

Line 11 — change to:
```swift
public struct EvaluationDetails: Sendable {
```

Line 15 — change to:
```swift
public struct Chunk: Identifiable, Sendable {
```

Line 22 — change to:
```swift
public enum State: String, CaseIterable, Sendable {
```

**Step 4: Build and run tests**

Run: `swift build 2>&1 | tail -3 && swift test --filter EvaluationDetailsSendableTests 2>&1 | tail -10`
Expected: 0 warnings, 4 tests pass.

**Step 5: Commit**

```bash
git add MLAIX/Types/EvaluationDetails.swift MLAIXTests/SendableConformanceTests.swift
git commit -m "feat: add Sendable to EvaluationDetails and nested types with tests"
```

---

### Task 4: Add Sendable to ChatParameters and nested types

**Files:**
- Modify: `MLAIX/Logic/Inference/llama.cpp/Types/ChatParameters.swift:12`, `:230`, `:291`, `:316`, `:320`
- Test: `MLAIXTests/SendableConformanceTests.swift` (append)

**Step 1: Write the failing test**

Append to `MLAIXTests/SendableConformanceTests.swift`:

```swift
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
```

**Step 2: Run test to verify direction**

Run: `swift test --filter ChatParametersSendableTests 2>&1 | tail -10`

**Step 3: Add Sendable conformance**

In `MLAIX/Logic/Inference/llama.cpp/Types/ChatParameters.swift`:

Line 12 — change to:
```swift
struct ChatParameters: Codable, Sendable {
```

Line 230 — change to:
```swift
public enum ParamKey: String, CaseIterable, CodingKey, Sendable {
```

Line 291 — change to:
```swift
struct SystemPrompt: Codable, Sendable {
```

Line 301 — change to (SystemPromptWrapper):
```swift
public struct SystemPromptWrapper: Codable, Sendable {
```

Line 316 — change to:
```swift
struct StreamOptions: Codable, Sendable {
```

Line 320 — change to:
```swift
struct ReasoningOptions: Codable, Sendable {
```

**Step 4: Build and run tests**

Run: `swift build 2>&1 | tail -3 && swift test --filter ChatParametersSendableTests 2>&1 | tail -10`
Expected: 0 warnings, 5 tests pass. **If build warns** about `Message.MessageSubset` or `OpenAIFunction` not being Sendable, we may need `@unchecked Sendable` instead. Handle in step 4.

**Step 5: Commit**

```bash
git add MLAIX/Logic/Inference/llama.cpp/Types/ChatParameters.swift MLAIXTests/SendableConformanceTests.swift
git commit -m "feat: add Sendable to ChatParameters and nested types with tests"
```

---

### Task 5: Add Sendable to ModelFamily (unchecked)

**Files:**
- Modify: `MLAIX/Types/Model/ModelFamily.swift:11`
- Test: `MLAIXTests/SendableConformanceTests.swift` (append)

**Step 1: Write the failing test**

Append to `MLAIXTests/SendableConformanceTests.swift`:

```swift
// MARK: - ModelFamily Sendable Tests

struct ModelFamilySendableTests {

    @Test func testModelFamilySendableAcrossTasks() async {
        // ModelFamily depends on HuggingFaceModel which is not Sendable,
        // so we use @unchecked Sendable. This test verifies thread-safe reads.
        let family = ModelFamily(
            name: "TestFamily",
            family: .llama,
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
            family: .qwen,
            models: []
        )
        #expect(family.id == "Qwen")
    }
}
```

**Step 2: Run test to verify direction**

Run: `swift test --filter ModelFamilySendableTests 2>&1 | tail -10`

**Step 3: Add @unchecked Sendable**

In `MLAIX/Types/Model/ModelFamily.swift`, change line 11:
```swift
public struct ModelFamily: Identifiable, Hashable, @unchecked Sendable {
```

Add a comment above:
```swift
/// Note: @unchecked Sendable because HuggingFaceModel (external) lacks Sendable.
/// All properties are value types; thread-safe for read-only sharing.
```

**Step 4: Build and run tests**

Run: `swift build 2>&1 | tail -3 && swift test --filter ModelFamilySendableTests 2>&1 | tail -10`
Expected: 0 warnings, 2 tests pass.

**Step 5: Commit**

```bash
git add MLAIX/Types/Model/ModelFamily.swift MLAIXTests/SendableConformanceTests.swift
git commit -m "feat: add @unchecked Sendable to ModelFamily with tests"
```

---

### Task 6: Final build verification and memory update

**Step 1: Full build + test**

Run: `swift build 2>&1 | tail -5 && swift test 2>&1 | tail -5`
Expected: 0 warnings, ~250 tests passing.

**Step 2: Update MEMORY.md**

Update the Sendable Gaps section to reflect all gaps are closed.

**Step 3: Commit**

```bash
git add -A && git commit -m "chore: update MEMORY.md after Sendable sweep"
```

---

## Summary

| Task | Type(s) | Approach | Tests Added |
|------|---------|----------|-------------|
| 1 | `LogLevel`, `OSLogLevel` | `: Sendable` | 4 |
| 2 | `Notifications` | `: Sendable` | 3 |
| 3 | `EvaluationDetails`, `Chunk`, `State` | `: Sendable` | 4 |
| 4 | `ChatParameters` + 4 nested types | `: Sendable` | 5 |
| 5 | `ModelFamily` | `@unchecked Sendable` | 2 |
| 6 | Verification | Build + test sweep | 0 |
| **Total** | **11 types** | | **~18 new tests** |

Expected final state: **~248 tests**, **37+ suites**, **0 warnings**.
