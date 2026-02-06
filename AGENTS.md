# Repository Guidelines

## Project Structure & Module Organization
- `MLAIX/`: main macOS app source (Swift/SwiftUI) for the MLAIX app. Key subfolders include `Logic/`, `Views/`, `Types/`, `Extensions/`, plus assets in `MLAIX/Assets.xcassets` and resources in `MLAIX/Resources`.
- `MLAIX/Logic/Utilities/Services/`: extracted service helpers (ContextCompressor, SpeechService, Tavily).
- `MLAIXTests/`: unit tests using Swift Testing.
- `Docs Images/`, `Markdown/`, `Features/`, `About/`: documentation and site content.
- `scripts/` and `setup.sh`: local setup helpers (signing, tooling).

## Build, Test, and Development Commands
- `swift build`: build the SwiftPM target (`MLAIX`).
- `swift run MLAIX`: run the MLAI app via SwiftPM.
- `swift test`: run unit tests in `MLAIXTests/`.
- `./setup.sh <CODE_SIGNING_IDENTITY>`: download/sign Marp.

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
