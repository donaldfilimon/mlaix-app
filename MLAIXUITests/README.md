# MLAIX UI Tests (XCUI)

These XCUI tests require Xcode to run. SwiftPM does not provide a target application path for XCUI tests.

**To run:**
1. Open the package in Xcode: `File > Open > Package.swift`
2. Create or edit a scheme that sets MLAIX as the host application for these tests
3. Run tests via `Product > Test` or ⌘U

**Alternative:** Use the desktop interaction tests in `MLAIXTests/PromptDesktopInteractionTests.swift`, which run via `swift test` when `MLAIX_UI_INTERACTION_TESTS=1` is set.
