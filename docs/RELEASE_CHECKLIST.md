# Release Checklist

Pre-release verification for MLAIX production builds (macOS, iOS/iPadOS, tvOS).

## Build & Test

- [ ] `swift build -c release --product MLAIX` succeeds
- [ ] `swift build --product MLAIXiOS` succeeds
- [ ] `swift build --product MLAIXtvos` succeeds
- [ ] `swift test` — all tests pass (464+ tests in 64 suites)
- [ ] `swift run MLAIX` — macOS app launches and core flows work

## Code Quality

- [ ] No `print()` in production paths (use `Logger`)
- [ ] Debug menu and Script Testing hidden in release (`#if DEBUG`)
- [ ] No hardcoded API keys or secrets
- [ ] Critical force unwraps replaced with safe handling (chat, inference, networking)

## Configuration

- [ ] Signing identity valid for distribution
- [ ] Entitlements correct for sandbox / network / file access

## Features Verification

- [ ] Local model inference works
- [ ] Remote API (OpenAI-compatible) works with user key
- [ ] Foundation Models (macOS 26+) when available (session management, retry on failure)
- [ ] MLX models (when selected); cache clears on model refresh
- [ ] Experts / RAG indexing and retrieval
- [ ] Function calling (arithmetic, web search, etc.)
- [ ] Deep Research agent
- [ ] Canvas, Diagrammer, Slide Studio, Detector
- [ ] Inline Writing Assistant
- [ ] Memory, keyboard shortcuts

## Documentation

- [ ] README.md up to date
- [ ] CLAUDE.md reflects current architecture
- [ ] docs/PLATFORMS.md — platform support and MLAIXShared
- [ ] docs/TESTING.md — test coverage and patterns
- [ ] docs/PRODUCTION.md — production readiness guide
- [ ] docs/evals/ralph/README.md — ralph-loop eval structure
- [ ] Getting started guide accurate

## Distribution

- [ ] Version number updated (if applicable)
- [ ] Release notes drafted
- [ ] DMG / notarization (if distributing outside App Store)
