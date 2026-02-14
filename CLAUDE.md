# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MLAIX (formerly Sidekick/MLAI) is a macOS SwiftUI app for chatting with local LLMs. It bundles `llama.cpp` as its inference backend, supports OpenAI-compatible remote APIs, Apple Foundation Models, and features RAG via "Experts", function calling, deep research agents, and tools (Detector, Diagrammer, Slide Studio, Inline Writing Assistant).

## Build & Test Commands

```bash
swift build                    # Build the MLAIX target
swift run MLAIX                # Run the app
swift test                     # Run all tests (unit + UI)
swift test --filter checkModelRecommendations  # Run a single test
MLAIX_UI_INTERACTION_TESTS=1 swift test  # Include desktop interaction tests (requires display)
```

**Static linking warning:** If you see "Swift compiler no longer supports statically linking the Swift libraries" during `swift build`, add `--no-static-swift-stdlib` (e.g. `swift build --no-static-swift-stdlib`). This option is not available for `swift test`. The warning comes from dependencies with older deployment targets and can be safely ignored.

## Key Architecture

### SwiftPM Module Layout

The SwiftPM package is named `MLAIX`. Source lives in `MLAIX/`; the module imported in code and tests is `MLAIX`:
- `@testable import MLAIX` in tests
- **`MLAIXShared`** — Unified SwiftUI + SwiftData library for macOS, iOS, iPadOS, tvOS (SharedMessageBubble, SharedEmptyChatView, SharedAPIConfig, SwiftData models)
- Executable targets: `MLAIX` (macOS), `MLAIXiOS` (iOS/iPadOS), `MLAIXtvos` (tvOS placeholder), `MLAIXWatch` (watchOS)
- Secondary target: `llama-server-watchdog` (process monitor)
- Test targets: `MLAIXTests` (path: `MLAIXTests/`), `MLAIXiOSTests`, `MLAIXSharedTests`
- UI tests: `MLAIXUITests/` (XCUI; run from Xcode). Desktop interaction: `PromptDesktopInteractionTests` in MLAIXTests (opt-in via `MLAIX_UI_INTERACTION_TESTS=1`)

### Singleton-Heavy Architecture

Most managers are `@MainActor @Observable` classes with `static let shared` singletons, injected via `@State`/`@Environment` from `MLAIXApp.swift` (NSObject subclasses like `DownloadManager` and `SpeechSynthesizer` still use `@EnvironmentObject`):
- `Model.shared` — Abstracts all inference (local llama.cpp, remote API, Apple Foundation Models, MLX)
- `ConversationManager.shared` — Persists and manages conversations (JSON; debounced saves, 350ms)
- `ExpertManager.shared` — Manages RAG experts with file/web/email resources
- `ModelManager.shared` — Model catalog and selection
- `LengthyTasksController.shared` — Tracks long-running operations

### Inference Layer (`Logic/Inference/`)

`Model` delegates to backends based on settings. **Text generation defaults to Apple Foundation Models when available** (`InferenceSettings.useFoundationModels` defaults to true; `Settings.useFunctions` defaults to false so chat uses Foundation for text-only).
- **`LlamaServer`** (actor) — Manages a local `llama-server` process on ports 4579 (main) / 9830 (worker). Handles SSE streaming, chat completions, function call parsing. Split across `LlamaServer+Chat.swift`, `LlamaServer+Networking.swift`, `LlamaServer+ServerLifecycle.swift`.
- **`LlamaServer+MLX`** / **`MLXRunner`** — Native Swift MLX bindings (MLXLLM) for MLX-format models. Uses `ModelContainer` cache; `clearModelCache()` on model refresh. Supports cancellation and distinct `modelLoadFailed` / `generationFailed` errors.
- **`FoundationModelsSupport`** / **`FoundationModelsClient`** — Apple Intelligence on macOS 26+ (FoundationModels framework). Streaming uses turn counting and session reset when context is exhausted; retry once on failure; respects task cancellation (`FoundationModelsError.cancelled`). Image Playground uses macOS 15.2+.
- **`PromptAnalyzer`** — CoreML classifier (`UserRequestClassifier.mlmodel`) that routes user prompts to text vs image generation

`Model` maintains two `LlamaServer` instances: `mainModelServer` (chat) and `workerModelServer` (function calling / agents).

### Persistence & SwiftData (`Logic/Utilities/`, `Logic/Data Models/`)

- **`SwiftDataStore`** — Holds `sharedContainer` and `mainContext` set at app launch for use by managers and (optionally) views.
- **`DataMigrationService`** — One-time JSON → SwiftData migration; sets `didMigrateToSwiftData`. Migrates inference records, memories, commands, server arguments, function selections. Archived JSON files are renamed to `.migrated`.
- **When migrated**, these managers load/save from SwiftData via `SwiftDataStore.mainContext`: `CommandManager`, `InferenceRecords`, `ServerArgumentsManager`. They keep the same public API (e.g. `[Command]`, `[InferenceRecord]`).
- **`ConversationManager`** — Still persists conversations as JSON (`conversations.json`); not yet backed by SwiftData.
- **`Memories`** — After migration, if the main JSON is missing, loads from the `.migrated` backup so data is not lost; continues to persist as JSON (memory type uses SimilaritySearchKit `IndexItem`).

### Function Calling (`Types/Conversation/Functions/`)

Functions conform to `DecodableFunctionCall` protocol. Default function categories in `Default Functions/`: Arithmetic, Calendar, Code, DeepResearch, Expert, File, Input, Reminder, Todo, Web. **Calculations are encouraged via JavaScriptCore**: `evaluate_expression` (safe arithmetic only) and `run_javascript` (full JS) in `CodeFunctions` use `JavaScriptRunner` (JavaScriptCore). Functions are called in a sequential loop until a result is obtained.

### Agent System (`Types/Agent/`)

`Agent` protocol requires `name`, `preview` (SwiftUI view), and `run() async throws -> LlamaServer.CompleteResponse`. `DeepResearchAgent` is the primary implementation for multi-step web research tasks.

### Expert/RAG System (`Types/Expert/`)

Experts contain domain-specific resources (files, folders, websites, emails). Uses `SimilaritySearchKit` for vector similarity. `GraphRAG` utilities (`Logic/Utilities/GraphRAG/`) provide entity extraction, community detection, and graph-based retrieval.

### Services (`Logic/Utilities/`)

Extracted utilities: `ContextCompressor` (summarizes tool outputs exceeding token limits), `SpeechService` (TTS), `Tavily` (web search API), `SwiftDataStore` (shared SwiftData container/context), `DataMigrationService` (JSON → SwiftData one-time migration).

## Conventions

- **Swift 6 strict concurrency** is enabled (`swiftLanguageModes: [.v6]`, `StrictConcurrency` upcoming feature). `LlamaServer` is an `actor`; most UI-facing managers are `@MainActor`. Types crossing actor boundaries must be `Sendable`. Mutable statics protected by external locks use `nonisolated(unsafe)`.
- **Modern observation** — Use `@Observable` for view models and UI state. Use `ObservableObject` + `@Published` only when required (e.g. `NSObject` subclasses: `DownloadManager`, `SpeechSynthesizer`, `AppDelegate`). Prefer `@Environment` over `@EnvironmentObject` for `@Observable` types.
- **Async** — Prefer `async`/`await` over completion handlers; use `.task { }` for async work in views when appropriate.
- **Swift Testing** — Unit tests use `import Testing` with `@Test` (not XCTest). XCTest is used only in `MLAIXUITests` for XCUI.
- **Conventional Commits** — `feat:`, `fix:`, `chore:`, etc.
- **4-space indentation**, braces on same line, `UpperCamelCase` types, `lowerCamelCase` members.
- **Asset references by string** — `Image("useExperts")`, `Color("brightGreen")`.
- **Git LFS** — The `marp` binary in Slide Studio resources is tracked via LFS (see `.gitattributes`).
- **Platform minimum**: All platforms require v26 (macOS 26, iOS 26, tvOS 26). Apple Silicon required for macOS.
- **Multi-platform**: macOS (full), iOS/iPadOS (remote API only), tvOS (placeholder), watchOS. Unified code in `MLAIXShared`. See `docs/PLATFORMS.md`.

## Testing

- **Framework**: Swift Testing (`import Testing`, `@Test`) for unit tests. XCTest only in `MLAIXUITests` (XCUI).
- **Location**: `MLAIXTests/`, `MLAIXiOSTests/`, `MLAIXSharedTests/`. Shared helpers in `TestUtilities.swift`.
- **Module**: `@testable import MLAIX` (or `MLAIXShared` for shared tests).
- **Guide**: See `docs/TESTING.md` for coverage, patterns, and running tests.

### Running tests

```bash
swift test                                    # All tests
swift test --filter checkModelRecommendations # Single test by name
swift test --filter ConversationPersistenceTests  # Suite by struct name
swift test --filter SenderTests               # Suite by struct name
```

### Patterns

- **Parameterized tests**: `@Test(arguments: [(a, b), ...])` for multiple inputs.
- **Descriptive assertions**: `#expect(x == y, "context when it fails")`.
- **MainActor tests**: `@Test @MainActor` for UI/manager code.
- **Shared setup**: Use `TestUtilities` for temp dirs, waiting on managers.
