# Testing Guide

This document describes how to run, write, and organize tests in the MLAIX project.

## Overview

- **Framework**: Swift Testing (`import Testing`, `@Test` functions)
- **Test targets**: `MLAIXTests`, `MLAIXiOSTests`, `MLAIXSharedTests`
- **Total tests**: 364 across 62 suites

## Running Tests

```bash
# All tests (macOS + iOS + Shared)
swift test

# Filter by suite name
swift test --filter ExtensionStringTests
swift test --filter ConversationPersistenceTests

# Filter by test name
swift test --filter checkModelRecommendations

# iOS-specific tests only
swift test --filter MLAIXiOSTests

# Shared library tests only
swift test --filter MLAIXSharedTests
```

### Optional: Desktop Interaction Tests

Some tests require a display and simulate UI interaction:

```bash
MLAIX_UI_INTERACTION_TESTS=1 swift test
# Or use the convenience script:
./scripts/run-ui-tests.sh
```

## Test Organization

| Directory        | Target         | Focus                                      |
|------------------|----------------|--------------------------------------------|
| `MLAIXTests/` | MLAIXTests     | macOS app: types, extensions, persistence   |
| `MLAIXiOSTests/` | MLAIXiOSTests  | iOS app: chat state, settings               |
| `MLAIXSharedTests/` | MLAIXSharedTests | Shared: models, config, Keychain, errors |

## Test Coverage by Area

### Core Types
- **SenderTests** — Sender enum encoding, raw values
- **MessageTests** — Message init, referenced URLs, reasoning
- **SourceTests** — Source, SourceInfo, SearchResult
- **CoreTypeTests** — Sender, Message, ReferencedURL, and related types

### Extensions
- **ExtensionStringTests** — `reasoningProcess`, `reasoningRemoved`, `specialReasoningTokens`
- **ExtensionCollectionTests** — `transpose`, `standardDeviation`, `variance`
- **ColorHexTests** — `Color(hex:)`, `toHex`, 6-char and 8-char hex parsing

### Persistence & State
- **ConversationPersistenceTests** — Debounced save, rapid saves
- **iOSChatStateTests** — Message handling, retry, state transitions, `handleIncomingURL` (Shortcuts/Watch deep links)
- **SharedModelsTests** — SharedChatMessage, SharedConversation

### Configuration & API
- **InferenceSettingsTests** — System prompts, settings
- **iOSSettingsTests** — SharedAPIConfig, hasConfiguredAPI
- **SharedChatErrorTests** — Error descriptions, LocalizedError
- **ThemePresetTests** — ThemePreset enum, accentHex format
- **AppearanceSettingsTests** — Appearance mode, font scale, theme presets

### Functions & Agents
- **FunctionTypesTests** — Function categories, parameters, schemas
- **PromptAnalyzerTests** — Text vs image routing

### Other
- **KnownModelConcurrencyTests** — Thread safety
- **JavaScriptRunnerTests** — Script execution, console capture
- **TrainingDataCollectorTests** — Export from conversations
- **PromptInputSyncTests** — Input field sync, selection clamping

## Writing Tests

### Basic Structure

```swift
import Foundation
import Testing
@testable import MLAIX

struct MyFeatureTests {
    @Test func testSomething() {
        let result = doSomething()
        #expect(result == expected)
    }
}
```

### Patterns

- **Parameterized tests**: `@Test(arguments: [(a, b), ...])` for multiple inputs
- **Async tests**: `@Test func testAsync() async { ... }`
- **MainActor tests**: `@Test @MainActor` for UI/manager code
- **Descriptive failures**: `#expect(x == y, "context when it fails")`

### Shared Helpers

`TestUtilities.swift` provides:
- `makeTempContainerUrl()` — Unique temp directory for test data
- `waitForLoaded(_ manager: ConversationManager)` — Wait for manager to finish loading

### Conventions

- One test file per feature or type (e.g. `ExtensionStringTests.swift`)
- Use `#expect` for assertions
- Prefer `@testable import` to access internal APIs when needed
- Avoid force unwraps in tests; use `guard let` or `try?` with clear failure messages

## Ralph-Loop Evals

Regression evals live in `docs/evals/ralph/`. See `docs/evals/ralph/README.md` for structure and ralph-loop compatibility. Key checks: strict concurrency (conc-002), build+test (build-001).

## Gaps & Recommendations

- **LlamaServer / Model inference**: Largely untested (integration-heavy; consider mocking)
- **ExpertManager**: Limited unit tests
- **UI / SwiftUI views**: No XCUITest coverage; desktop interaction tests are opt-in
- **Ralph evals**: Proxy scoring only; consider live model-backed scoring for accuracy

## Related

- `docs/RELEASE_CHECKLIST.md` — Pre-release verification
- `docs/IMPROVEMENTS_RESEARCH.md` — Testing gaps and recommendations
- `docs/APPEARANCE.md` — Appearance customization (theme, accent, font scale)
- `docs/APPLE_WATCH_SHORTCUTS_WIDGETS.md` — Watch, Shortcuts, Widgets
- `CLAUDE.md` — Build commands and module layout
