# MLAIX UI Tests (XCUI)

XCUI tests for the MLAIX macOS app. They require **Xcode** and a **scheme that sets MLAIX as the host application**.

## Running the tests

1. Open the package in Xcode: **File → Open →** select `Package.swift`.
2. Ensure the **MLAIX** scheme is selected and that **MLAIXUITests** is included in the Test action:
   - **Product → Scheme → Edit Scheme… (⌘<)**
   - Select **Test** in the left sidebar.
   - Under **Testables**, check **MLAIXUITests** and set the **Host Application** to **MLAIX**.
   - In the **Arguments** tab (or **Environment Variables** for the test run), add **`MLAIX_UI_TEST_HOST_AVAILABLE=1`** so the UI tests run instead of skipping.
3. Run tests: **Product → Test** or **⌘U**.

To run only UI tests from the command line (with Xcode):

```bash
xcodebuild test -scheme MLAIX -only-testing:MLAIXUITests -destination 'platform=macOS'
```

(Requires an Xcode-generated scheme that includes the MLAIXUITests target and MLAIX as the host.)

## What’s tested

- **Launch**: App launches and reaches foreground; launch performance.
- **Main window**: Primary sidebar exists; content column exists.
- **Navigation**: Sidebar shows **Conversations** and **Tools**; tapping **Tools** keeps content column visible.
- **Toolbar**: **New Conversation** and **Toolbox** buttons exist.
- **Actions**: New conversation from toolbar; empty state shows a way to create a new conversation when none is selected.
- **Screenshots**: Launch screen and main window (attachments kept for inspection).

## Accessibility identifiers

The app exposes these identifiers for stable UI testing (see `MLAIXUITestHelpers.MLAIXAccessibility`):

| Identifier | Where |
|------------|--------|
| `primarySidebar` | First column (section list) |
| `sidebar.conversations`, `sidebar.tools`, etc. | Section rows |
| `contentColumn` | Middle column |
| `newConversationButton` | Sidebar “New Conversation” button |
| `toolbar.newConversation` | Toolbar “New Conversation” button |
| `toolbar.toolbox` | Toolbar “Toolbox” button |
| `noConversationSelected` | Empty state when no conversation is selected |
| `noConversation.newConversationButton` | “New Conversation” in that empty state |

## Helpers

- **`launchMLAIX(arguments:environment:timeout:)`** – Launches the app, optionally with arguments/environment, and waits until it’s in the foreground.
- **`XCTAssertElementExists(_:timeout:requireHittable:)`** – Asserts an element exists (and optionally is hittable) within the timeout.
- **`MLAIXAccessibility`** – Central list of accessibility identifiers used by the app.

## Note on `swift test`

`swift test` does not set a host application for XCUI tests. When the host is not set, all MLAIXUITests **skip** (via `skipIfHostAppUnavailable()`), so `swift test` completes with exit code 0. To run the UI tests, use Xcode (or `xcodebuild test`) with MLAIX as the host and **`MLAIX_UI_TEST_HOST_AVAILABLE=1`** in the scheme. For automated tests that run with `swift test`, see **MLAIXTests/PromptDesktopInteractionTests** (opt-in via `MLAIX_UI_INTERACTION_TESTS=1`).
