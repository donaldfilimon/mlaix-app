# Repository Guidelines

## Project Structure & Module Organization
- `Sidekick/`: main macOS app source (Swift/SwiftUI) for the MLAI app. Key subfolders include `Logic/`, `Views/`, `Types/`, `Extensions/`, plus assets in `Sidekick/Assets.xcassets` and resources in `Sidekick/Resources`.
- `SidekickTests/`: unit tests using Swift Testing.
- `Docs Images/`, `Markdown/`, `Features/`, `About/`: documentation and site content.
- `scripts/` and `setup.sh`: local setup helpers (signing, tooling).

## Build, Test, and Development Commands
- `swift build`: build the SwiftPM target (`MLAI`).
- `swift run MLAI`: run the MLAI app via SwiftPM.
- `swift test`: run unit tests in `SidekickTests/`.
- `./setup.sh <CODE_SIGNING_IDENTITY>`: download/sign Marp.

## Coding Style & Naming Conventions
- Use standard Xcode formatting (4-space indentation, braces on the same line).
- Types/protocols use `UpperCamelCase` (e.g., `ConversationManager`); methods/vars use `lowerCamelCase` (e.g., `loadIndex()`).
- Keep files grouped by feature area (e.g., `Views/Chat/...`, `Logic/Inference/...`).
- Prefer asset lookups by string name (e.g., `Image("useExperts")`, `Color("brightGreen")`).

## Testing Guidelines
- Unit tests use Swift Testing (`import Testing`) and `@Test` functions.
- Keep tests in `SidekickTests/` and name them descriptively (e.g., `checkModelReccomendations()`).

## Commit & Pull Request Guidelines
- Commit messages follow Conventional Commits style (`feat:`, `fix:`, `chore:`), per recent history.
- PRs should include a concise summary, test results (command + output), and screenshots for UI changes.

## Configuration Notes
- The SwiftPM module name is `MLAI` (use `@testable import MLAI` in tests).
