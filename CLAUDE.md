# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MLAI (formerly Sidekick) is a macOS SwiftUI app for chatting with local LLMs. It bundles `llama.cpp` as its inference backend, supports OpenAI-compatible remote APIs, Apple Foundation Models, and features RAG via "Experts", function calling, deep research agents, and tools (Detector, Diagrammer, Slide Studio, Inline Writing Assistant).

## Build & Test Commands

```bash
swift build                    # Build the MLAI target
swift run MLAI                 # Run the app
swift test                     # Run all tests (SidekickTests/)
swift test --filter MLAITests/checkModelReccomendations  # Run a single test
```

**First-time setup** requires signing the bundled `marp` binary:
```bash
security find-identity -p codesigning -v   # Find your signing identity
./setup.sh <SIGNING_IDENTITY>              # Download and sign marp
```

## Key Architecture

### SwiftPM Module Layout

The SwiftPM package is named `MLAI` (not "Sidekick"). Source lives in `Sidekick/` but the module imported in code and tests is `MLAI`:
- `@testable import MLAI` in tests
- Executable target: `MLAI`
- Secondary target: `llama-server-watchdog` (process monitor)
- Test target: `MLAITests` (path: `SidekickTests/`)

### Singleton-Heavy Architecture

Most managers are `@MainActor` classes with `static let shared` singletons, injected as `@StateObject`/`@EnvironmentObject` from `SidekickApp.swift`:
- `Model.shared` — Abstracts all inference (local llama.cpp, remote API, Apple Foundation Models)
- `ConversationManager.shared` — Persists and manages conversations (debounced saves, 350ms)
- `ExpertManager.shared` — Manages RAG experts with file/web/email resources
- `ModelManager.shared` — Model catalog and selection
- `LengthyTasksController.shared` — Tracks long-running operations

### Inference Layer (`Logic/Inference/`)

`Model` delegates to backends based on settings:
- **`LlamaServer`** (actor) — Manages a local `llama-server` process on ports 4579 (main) / 9830 (worker). Handles SSE streaming, chat completions, function call parsing. Split across `LlamaServer+Chat.swift`, `LlamaServer+Networking.swift`, `LlamaServer+ServerLifecycle.swift`.
- **`FoundationModelsSupport`** — Apple Intelligence on macOS 15.2+
- **`PromptAnalyzer`** — CoreML classifier (`UserRequestClassifier.mlmodel`) that routes user prompts to text vs image generation

`Model` maintains two `LlamaServer` instances: `mainModelServer` (chat) and `workerModelServer` (function calling / agents).

### Function Calling (`Types/Conversation/Functions/`)

Functions conform to `DecodableFunctionCall` protocol. Default function categories in `Default Functions/`: Arithmetic, Calendar, Code, DeepResearch, Expert, File, Input, Reminder, Todo, Web. Functions are called in a sequential loop until a result is obtained.

### Agent System (`Types/Agent/`)

`Agent` protocol requires `name`, `preview` (SwiftUI view), and `run() async throws -> LlamaServer.CompleteResponse`. `DeepResearchAgent` is the primary implementation for multi-step web research tasks.

### Expert/RAG System (`Types/Expert/`)

Experts contain domain-specific resources (files, folders, websites, emails). Uses `SimilaritySearchKit` for vector similarity. `GraphRAG` utilities (`Logic/Utilities/GraphRAG/`) provide entity extraction, community detection, and graph-based retrieval.

### Services (`Logic/Utilities/Services/`)

Extracted utilities: `ContextCompressor` (summarizes tool outputs exceeding token limits), `SpeechService` (TTS), `Tavily` (web search API).

## Conventions

- **Swift 6 strict concurrency** is enabled (`swiftLanguageModes: [.v6]`, `StrictConcurrency` upcoming feature). `LlamaServer` is an `actor`; most UI-facing managers are `@MainActor`. Types crossing actor boundaries must be `Sendable`. Mutable statics protected by external locks use `nonisolated(unsafe)`.
- **Swift Testing framework** — Tests use `import Testing` with `@Test` functions (not XCTest).
- **Conventional Commits** — `feat:`, `fix:`, `chore:`, etc.
- **4-space indentation**, braces on same line, `UpperCamelCase` types, `lowerCamelCase` members.
- **Asset references by string** — `Image("useExperts")`, `Color("brightGreen")`.
- **Git LFS** — The `marp` binary in Slide Studio resources is tracked via LFS (see `.gitattributes`).
- Platform minimum: macOS 15 (Swift <6.2) or macOS 26 (Swift 6.2+). Apple Silicon required.
