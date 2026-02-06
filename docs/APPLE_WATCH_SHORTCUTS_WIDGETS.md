# Apple Watch, Siri Shortcuts & Widgets

This document describes MLAIX support for Apple Watch, Siri Shortcuts, and Home Screen widgets.

## Apple Watch

**MLAIXWatch** is a companion watchOS app that provides quick access to MLAIX on iPhone.

- **Build**: `swift build --target MLAIXWatch`
- **Run**: Requires pairing with an iPhone running MLAIX (MLAIXiOS)
- **UI**: Simple "Open MLAIX on iPhone" screen; tap to open the main app on your phone

The watch app is a standalone executable. For full Watch Connectivity (e.g. sending prompts from the watch), you would add `WatchConnectivity` and extend `iOSChatState` to receive messages from the watch.

## Siri Shortcuts (App Intents)

MLAIX includes **App Intents** for Siri Shortcuts on both **iOS** and **macOS**:

| Shortcut | Description |
|----------|-------------|
| **Open MLAIX** | Opens the MLAIX app |
| **New Chat** | Opens MLAIX and starts a new conversation |
| **Ask MLAIX** | Opens MLAIX with a prompt ready to send (parameter: prompt text) |

### Usage

1. Build and run MLAIX (macOS) or MLAIXiOS (iPhone/iPad) on your device or simulator
2. In the Shortcuts app, search for "MLAIX" or add actions from the app
3. Say "Hey Siri, open MLAIX" or "Hey Siri, new chat in MLAIX"
4. For "Ask MLAIX", provide a prompt: "Hey Siri, ask MLAIX what's the weather"

### URL Scheme (for Xcode projects)

To enable deep linking from Shortcuts and the Watch, the app must register the `mlaix` URL scheme:

- `mlaix://` — Open app
- `mlaix://new-chat` — New conversation
- `mlaix://ask?prompt=...` — New chat with prompt pre-filled

**SwiftPM limitation**: Swift Package Manager does not support custom `Info.plist` for executables. To add the URL scheme:

1. Create an Xcode project that uses this package
2. Add `MLAIXiOS/Info.plist` (or merge its `CFBundleURLTypes` into your app's Info.plist)
3. Build and run from Xcode

The `Info.plist` in `MLAIXiOS/` is excluded from the SwiftPM target but kept for reference.

## Widgets

**MLAIXWidget** provides a Home Screen widget for quick access.

**SwiftPM limitation**: Widget extensions require an Xcode project. SwiftPM does not support app extension targets.

### Adding the Widget

1. Create an Xcode project for MLAIX (or open an existing one that uses this package)
2. Add a new target: **File → New → Target → Widget Extension**
3. Name it "MLAIXWidgetExtension"
4. Replace the generated widget code with the contents of `MLAIXWidgets/MLAIXWidget.swift`
5. Add the `mlaix` URL scheme to the **main app's** Info.plist (see above)
6. Build and run

The widget shows the MLAIX icon and "New Chat"; tapping it opens the app to a new conversation.

### Widget Code Location

The widget implementation lives in `MLAIXWidgets/MLAIXWidget.swift`. Copy this file into your Widget Extension target.

## Summary

| Feature | SwiftPM | Xcode Project |
|---------|---------|---------------|
| Apple Watch (MLAIXWatch) | ✅ Built-in | ✅ |
| App Intents (Shortcuts) | ✅ Built-in | ✅ |
| URL scheme (mlaix://) | ❌ | ✅ Add Info.plist |
| Widget Extension | ❌ | ✅ Add extension target |

For full functionality (Shortcuts opening the app via URL, Watch opening the app, Widget deep links), use an Xcode project that wraps this package and add the Info.plist URL scheme + Widget Extension as described above.
