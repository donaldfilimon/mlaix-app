# Ralph Loop Regression Evals

Regression evaluations for MLAIX, covering UI behavior, concurrency, build stability, appearance settings, cross-platform builds, Siri Shortcuts, color utilities, and full test suite health.

## Structure

- `prompts.json` — Eval manifest with structured prompts (id, category, severity, command, expected outcome, related tests)
- `results.scored.json` — Latest scored results
- `results.raw.json` — Legacy raw results (kept for backwards compatibility)
- `summary.md` — Latest run summary with pass/fail verdict
- `runs/<timestamp>/` — Per-run artifacts (results, summary, prompts snapshot)

## Eval Categories

| ID prefix | Category | Focus |
|-----------|----------|-------|
| `ui-*` | UI | Input field typing, cursor tracking, toggles, chips, IME |
| `conc-*` | Concurrency | Actor isolation, strict Swift 6 concurrency, dispatch safety |
| `build-*` | Build | SwiftPM release build and full test suite |
| `appearance-*` | Appearance | Theme presets, accent colors, font scale clamping |
| `platform-*` | Platform | Cross-platform builds (iOS, watchOS, tvOS) |
| `intents-*` | Intents | Siri Shortcuts URL scheme parsing and compilation |
| `color-*` | Color | Hex color init/round-trip utilities |
| `test-*` | Test | Full test suite pass/fail gate |

## Severity Levels

| Level | Meaning |
|-------|---------|
| `critical` | Must pass for any release. Blocks CI. |
| `high` | Should pass. Failures require investigation before release. |
| `medium` | Nice to have. Failures are warnings, not blockers. |

## Running Evals

### Via Subagent

The `ralph-loop` Cursor subagent (`.cursor/agents/ralph-loop.md`) can execute evals interactively. It reads `prompts.json`, runs the `command` from each entry, and records results.

### Manual

For individual categories:

```bash
# UI tests
swift test --filter PromptInputSyncTests

# Concurrency check
swift build  # StrictConcurrency is enabled in Package.swift

# Full build + test
swift build -c release && swift test

# Appearance tests
swift test --filter AppearanceSettingsTests

# Platform builds
swift build --product MLAIXiOS
swift build --product MLAIXWatch
swift build --product MLAIXtvos

# Color tests (in MLAIXSharedTests target)
swift test --filter ColorHexTests

# Intents / URL scheme tests (in MLAIXiOSTests target)
swift test --filter iOSChatStateTests

# Desktop interaction (requires display)
MLAIX_UI_INTERACTION_TESTS=1 swift test --filter PromptDesktopInteractionTests
```

## Prompt Schema

Each entry in `prompts.json`:

```json
{
  "id": "ui-001",
  "category": "ui",
  "severity": "critical",
  "prompt": "Human-readable description of the check.",
  "expected_outcome": "What a passing result looks like.",
  "command": "swift test --filter PromptInputSyncTests",
  "related_tests": ["TestSuite/testName"]
}
```

### Fields

| Field | Required | Description |
|-------|----------|-------------|
| `id` | yes | Unique identifier; prefix determines category |
| `category` | yes | One of: `ui`, `conc`, `build`, `appearance`, `platform`, `intents`, `color`, `test` |
| `severity` | yes | `critical`, `high`, or `medium` |
| `prompt` | yes | Human-readable description of what to check |
| `expected_outcome` | yes | What a passing result looks like |
| `command` | yes | Shell command executed by the runner script and subagent |
| `related_tests` | yes | Array of Swift test names for reference (may be empty) |

### Test Targets

Commands reference one of three test targets:

| Target | Path | Contents |
|--------|------|----------|
| `MLAIXTests` | `MLAIXTests/` | Main macOS tests (PromptInputSync, Appearance, etc.) |
| `MLAIXSharedTests` | `MLAIXSharedTests/` | Cross-platform tests (ColorHexTests) |
| `MLAIXiOSTests` | `MLAIXiOSTests/` | iOS-specific tests (iOSChatStateTests) |

## Ralph-Loop Compatibility Notes

- **conc-002**: Swift 6 strict concurrency is enabled in `Package.swift` (`.enableUpcomingFeature("StrictConcurrency")`).
- **build-001**: Run `swift build -c release && swift test`.
- **Package name**: `MLAIX` (not `MLAI`). Test targets: `MLAIXTests`, `MLAIXSharedTests`, `MLAIXiOSTests`.

## Current Status

See `summary.md` for the latest run results and pass/fail verdict.
