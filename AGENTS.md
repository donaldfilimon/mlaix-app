# Repository Guidelines

## Project Structure & Module Organization

- `MLAIX/`: main macOS app source (Swift/SwiftUI) for the MLAIX app. Key subfolders include `Logic/`, `Views/`, `Types/`, `Extensions/`, `Views/Tools/` (Detector, Diagrammer, Node Editor, Slide Studio, etc.), plus assets and resources.
- `MLAIX/Logic/Utilities/`: utility helpers (ContextCompressor, SpeechService, Tavily, GraphRAG).
- `MLAIXTests/`: unit tests using Swift Testing.
- `Docs Images/`, `Markdown/`, `Features/`, `About/`: documentation and site content.

## Build, Test, and Development Commands

- `swift build`: build the SwiftPM target (`MLAIX`).
- `swift run MLAIX`: run the MLAIX app via SwiftPM.
- `swift test`: run unit tests (479 tests in 65 suites across `MLAIXTests/`, `MLAIXiOSTests/`, `MLAIXSharedTests/`).

## Coding Style & Naming Conventions

- Use standard Xcode formatting (4-space indentation, braces on the same line).
- Types/protocols use `UpperCamelCase` (e.g., `ConversationManager`); methods/vars use `lowerCamelCase` (e.g., `loadIndex()`).
- Keep files grouped by feature area (e.g., `Views/Chat/...`, `Logic/Inference/...`).
- Prefer asset lookups by string name (e.g., `Image("useExperts")`, `Color("brightGreen")`).

## Testing Guidelines

- Unit tests use Swift Testing (`import Testing`) and `@Test` functions.
- Keep tests in `MLAIXTests/` and name them descriptively (e.g., `checkModelRecommendations()`).

## Commit & Pull Request Guidelines

- Commit messages follow Conventional Commits style (`feat:`, `fix:`, `chore:`), per recent history.
- PRs should include a concise summary, test results (command + output), and screenshots for UI changes.

## Configuration Notes

- The SwiftPM module name is `MLAIX` (use `@testable import MLAIX` in tests).
