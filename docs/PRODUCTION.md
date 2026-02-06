# Production Readiness Guide

Steps to prepare MLAIX for production release (macOS, iOS, tvOS).

## Prerequisites

- Xcode or Swift 6.2+ toolchain
- Apple Developer account (for signing and distribution)
- `./setup.sh <SIGNING_IDENTITY>` run for marp binary (Slide Studio)

## Pre-Release Verification

**Quick run:** `./scripts/pre-release.sh` — builds all products and runs tests.

### 1. Build All Products

```bash
swift build -c release --product MLAIX
swift build --product MLAIXiOS
swift build --product MLAIXtvos
```

### 2. Run Tests

```bash
swift test
# Expect: 332+ tests in 59 suites passing
```

### 3. Manual Verification

- [ ] `swift run MLAIX` — macOS app launches
- [ ] Local model inference works (if model installed)
- [ ] Remote API works with user-provided key
- [ ] Experts, function calling, Deep Research functional
- [ ] Debug menu and Script Testing **not** visible in release build

### 4. Code Quality Checklist

- [ ] No `print()` in production paths (use `Logger`)
- [ ] No hardcoded API keys or secrets
- [ ] Critical force unwraps replaced with safe handling

## Version and Metadata

Update before each release:

| Location | Key | Example |
|----------|-----|---------|
| `MLAIX/Info.plist` | `CFBundleShortVersionString` | `1.0.0` |
| `MLAIX/Info.plist` | `CFBundleVersion` | `100` (build number) |

For iOS: Update `MLAIXiOS/Info.plist` if present.

## Signing and Notarization (macOS)

1. **Sign marp binary** (required for Slide Studio):
   ```bash
   security find-identity -p codesigning -v
   ./setup.sh "Apple Development: Your Name (TEAM_ID)"
   ```

2. **Sign the app** (for distribution outside App Store):
   - Use Xcode: Product → Archive → Distribute App
   - Or `codesign` for ad-hoc distribution

3. **Notarization** (for Gatekeeper):
   - Required for DMG/zip distribution
   - Use `xcrun notarytool` or Xcode Organizer

## Distribution Options

| Method | Notes |
|--------|-------|
| **Direct DMG** | Sign + notarize; users download and open |
| **Mac App Store** | Requires App Store Connect, sandboxing |
| **TestFlight** | For iOS beta; macOS supported |
| **Ad-hoc** | For internal testing; limited devices |

## CI/CD

`.github/workflows/ci.yml` runs on push/PR to `main`:

- Builds all products in release mode
- Runs full test suite
- Uses `macos-14` runner

## Related Docs

- [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md) — Full pre-release checklist
- [PLATFORMS.md](PLATFORMS.md) — Platform support and builds
- [TESTING.md](TESTING.md) — Test coverage and patterns
