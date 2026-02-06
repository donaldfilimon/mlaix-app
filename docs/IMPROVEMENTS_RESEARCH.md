# MLAI Codebase: Research on Additions and Improvements

Research conducted across the MLAIX/ codebase, Package.swift, tests, and evals. Organized by category with actionable recommendations.

---

## 1. Deprecated SwiftUI APIs

### 1.1 `onChange(of:perform:)` — Single-parameter closure (deprecated in Swift 5.9+) ✅ Done

Migrated all single-parameter closures to the two-param form. The old `.onChange(of: value) { ... }` form is deprecated. Use `.onChange(of: value) { oldValue, newValue in ... }` instead. All call sites now use the two-parameter form.

### 1.2 `initial: false` on onChange ✅ Done

Added `initial: false` where handlers perform save/sync/notification actions that should not run on initial view appear (avoids redundant work and spurious model reloads).

---

## 2. Logging and Debugging

### 2.1 Replace `print()` with `Logger` / `OSLog` ✅ Done

Migrated ~40 call sites to `Logger` across views, logic, data models, inference, accessibility, and extensions. Extension+URL already uses Logger. Remaining `print()` only in MLXRunner (Python), llama-server-watchdog (CLI), and commented ServerHealth.

### 2.2 Deprecated API with migration path ✅ N/A

Extension+URL only exposes async `verifyURL(url:timeoutInterval:)`; no deprecated callback overload exists. All callers use the async version.

---

## 3. Concurrency and Main Thread

### 3.1 `DispatchQueue.main.async` → `MainActor` ✅ Done

Migrated all call sites to `Task { @MainActor in ... }` and `Task.sleep` for delayed work. Files updated: MultilineTextEditor, PromptInputField, PromptController, LiquidView, BubbleAnimationView, CopyButton, MessagesView, CapsuleMenuButton, MermaidRenderer, SpeechService.

---

## 4. Dependencies

### 4.1 Pinned to `branch: "main"` (unstable)

| Package | Current | Recommendation |
|---------|---------|----------------|
| Default-Models | branch: main | Pin to tag if available |
| EventSource | branch: main | Pin to tag if available |
| ExtractKit-macOS | branch: main | Pin to tag if available |
| FSKit-macOS | branch: main | Pin to tag if available |
| GoogleSearch | branch: main | Pin to tag if available |
| LaTeXSwiftUI | branch: main | Pin to tag if available |
| LaunchAtLogin-Modern | branch: main | Pin to tag if available |
| similarity-search-kit | branch: mlai-resources | Keep if custom fork; consider tag |

**Recommendation:** Prefer version pins (e.g. `from: "x.y.z"`) for reproducible builds. Use branches only when necessary (e.g. custom forks).

### 4.2 Potential updates

Check for newer versions of: AXSwift, CodeEditorView, Highlightr, KeyboardShortcuts, SecureDefaults, Splash, SQLite.swift, SwiftUI-Shimmer, SymbolPicker, swift-markdown-ui, NetworkImage, WebViewKit.

---

## 5. Architecture and Patterns

### 5.1 `ObservableObject` vs `@Observable` (Swift 5.9+)

~90+ uses of `@StateObject` / `@EnvironmentObject` with `ObservableObject`. `@Observable` reduces boilerplate and can improve performance.

**Recommendation:** Incrementally migrate managers (e.g. `ConversationState`, `PromptController`) to `@Observable`. Update views to use `@State` / `@Environment` instead of `@StateObject` / `@EnvironmentObject` where applicable. Start with leaf view models.

### 5.2 Singleton usage

Heavy use of `static let shared` (Model, ConversationManager, ExpertManager, etc.). Consider dependency injection for testability, or keep singletons but ensure they are `@MainActor` and well-isolated.

---

## 6. Testing

### 6.1 Current coverage

- 21 test files in MLAIXTests/, plus MLAIXiOSTests, MLAIXSharedTests
- 336+ tests in 59 suites (Swift Testing)
- Areas: Extension+String (reasoningProcess, reasoningRemoved), Extension+Collection (transpose, variance), PromptInputSync, ConversationPersistence, KnownModel, Message/Source, Expert, Function types, InferenceSettings, PromptAnalyzer, TrainingDataCollector, CoreMLTrainer, BackendAutoConfig, JavaScriptRunner, SettingsModelSupport, iOS chat state, SharedAPIConfig, SharedChatError, KeychainHelper, etc.

### 6.2 Gaps

- LlamaServer / Model inference paths largely untested (integration-heavy)
- ExpertManager: limited unit tests
- UI / SwiftUI views: no UI tests
- Ralph evals: proxy scoring only; consider live model-backed scoring

**Recommendation:** Add integration tests for inference paths; consider UI tests for core flows (e.g. prompt input, send).

---

## 7. Code Quality

### 7.1 Force unwraps (`!`) ✅ Critical paths done

Critical paths have been hardened: `try!` removed from Message, Function, ExpertFunctions JSON encoding; cheatsheet loading; FileManager.createDirectory; Extension+String (splitByLatex, removingBase64Images, reasoningProcess, reasoningRemoved); DuckDuckGoSearch regex; WebsiteSelectionView NSDataDetector. Additional fixes: Message.swift (specialTokenSet, NSImage contentsOf), Function.swift (getJsonSchema, request description UTF-8 decode), DownloadManager (mirror URL, default model URL), CalendarFunctions, ReminderFunctions (String(data:encoding:) with encodingFailed). MLAIXiOSApp SwiftData init uses file→in-memory fallback with preconditionFailure only if both fail. Remaining `!` are mostly optional unwraps in lower-traffic code. Accessibility `as!` casts (AXUIElement/AXValue) remain for C API bridging; lower priority.

### 7.2 TODO / FIXME

No `TODO` or `FIXME` comments found. Either the codebase is clean or such markers are not used.

---

## 8. Platform and APIs

### 8.1 macOS version checks

- `#available(macOS 15, *)` — used for SwiftUI features, SF Symbols
- `#available(macOS 15.2, *)` — Foundation Models (Image Playground)
- `#available(macOS 26.0, *)` — Apple Intelligence / FoundationModels framework

**Recommendation:** Keep version checks; consider extracting into helpers (e.g. `enum PlatformCapabilities`) for clarity.

### 8.2 CLAUDE.md accuracy

- CLAUDE.md says "FoundationModelsSupport — Apple Intelligence on macOS 15.2+". Actual gating is macOS 26.0 for `FoundationModels` and macOS 15.2 for Image Playground. Consider updating the doc.

---

## 9. Ralph Eval

- 24 evaluations, proxy scoring
- Overall 3.8 < 4.0 threshold
- Recommendation in summary: raise proxy criteria or switch to live model-backed scoring

**Recommendation:** Run live model-backed evals periodically; add more prompt coverage for input field, cursor, and toggle behavior.

---

## 10. Quick Wins (Low Effort, High Value)

| Priority | Change | Effort | Impact | Status |
|----------|--------|--------|--------|--------|
| 1 | Fix deprecated `onChange` (add `_, newValue in`) | Low | Removes deprecation warnings | ✅ Done |
| 2 | Replace `print()` with Logger | Low | Cleaner logs | ✅ Done |
| 3 | Remove deprecated `verifyURL` callback overload | Low | Less dead code | ✅ N/A (none exists) |
| 4 | Pin branch dependencies to tags where possible | Medium | Reproducible builds | Pending |
| 5 | Add `initial: false` to `onChange` where initial run is unwanted | Low | Correct behavior | ✅ Done |

---

## 11. Medium-Term Improvements

| Area | Change | Effort | Status |
|------|--------|--------|--------|
| Logging | Centralize Logger, replace print() | Medium | ✅ Done |
| Concurrency | Migrate DispatchQueue.main.async to MainActor | Medium | ✅ Done |
| State | Pilot @Observable on 1–2 managers | Medium | Partial (ConversationState) |
| Tests | Add settings + manager unit tests | Medium | Partial (JavaScriptRunner, SettingsModelSupport) |
| Dependencies | Audit and update versions | Low–Medium | Pending |

---

## 12. SwiftData Migration (Optional)

**Current:** Conversations and messages are persisted as JSON via `ConversationManager` (Codable + `datastoreUrl`).

**SwiftData option:** For richer querying, relationships, and system integration:

1. Add `import SwiftData` and `@Model` to `Conversation` and `Message` (convert from struct to class).
2. Create `ModelContainer` with schema for `Conversation` and `Message`.
3. Replace `ConversationManager` JSON load/save with `ModelContext` fetch/insert/delete.
4. Use `@Query` in SwiftUI views for reactive updates.

**Trade-offs:** SwiftData is built on Core Data; migration requires schema design and data migration. JSON is simpler and already works. Consider SwiftData only if query/relationship needs justify the refactor.

---

## 13. Longer-Term / Larger Efforts

| Area | Change | Effort |
|------|--------|--------|
| Multi-platform | iOS / iPadOS support (see prior analysis) | ✅ Done |
| Architecture | Broader @Observable migration | High |
| Testing | Live model-backed Ralph evals | Medium |
| Safety | Systematic force-unwrap audit | High |

---

## Script Testing (Built-in JS + WebView) ✅ Done

- **JavaScriptRunner** — `executeWithConsoleOutput()` with `console.log`/`warn`/`error` capture.
- **ScriptTestingView** — Code editor, Run (⌘↵), Output/Console/WebView tabs, Examples menu, progress indicator.
- **Debug menu** — "Script Testing (JS + WebView)" opens the window.
- **Tests** — `JavaScriptRunnerTests` for execution and console levels.

---

## Production Readiness ✅ Done

- **Debug menu** — Hidden in release builds (`#if DEBUG`)
- **Script Testing** — Debug-only window and notification handler
- **Force unwraps** — Replaced in ChatParameters.toJSON, LlamaServer+Networking.url, LlamaServer+Chat.getCompletion, WebFunctions, Extension+Tavily
- **FatalErrors** — Replaced in PromptController (speech), WebFunctions (Tavily case added; encoding uses WebSearchError.encodingFailed)
- **CI** — `.github/workflows/ci.yml` runs `swift build -c release` and `swift test` on push/PR
- **Release checklist** — `docs/RELEASE_CHECKLIST.md` for pre-release verification

---

## Summary

- **Immediate:** ✅ Fix deprecated `onChange`, replace `print()` with Logger, concurrency (DispatchQueue → MainActor).
- **Short-term:** ✅ `initial: false` on onChange where needed. Dependency pins pending.
- **Production:** ✅ Debug hidden, critical force unwraps fixed, CI workflow, release checklist.
- **Medium-term:** Broader @Observable migration, expand tests, refine evals.
- **Long-term:** ✅ Multi-platform (macOS, iOS, tvOS), MLAIXShared library, SwiftData persistence, Keychain for API keys.
- **Recent:** ✅ iOS SwiftData persistence, Keychain for API keys, SharedChatError, New Chat button, Extension+String/Collection tests, docs/TESTING.md, 332+ tests.
