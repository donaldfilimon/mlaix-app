# MLAIX Platform Support

MLAIX supports multiple Apple platforms with different feature sets.

## Supported Platforms

| Platform | Status | Features |
|----------|--------|----------|
| **macOS** | Full | Local models (llama.cpp), MLX (native Swift), remote API, Apple Foundation Models (macOS 26+; session management, retry on context exhaustion), Experts, function calling, Deep Research, all tools. Commands, inference records, and server arguments use SwiftData when migrated from JSON. |
| **iOS / iPadOS** | Mobile | Remote API only (OpenAI-compatible). Chat, Markdown rendering. |
| **tvOS** | Placeholder | Coming soon. Placeholder app for future support. |

## Building

### macOS
```bash
swift build --product MLAIX
swift run MLAIX
```

### iOS / iPadOS
```bash
swift build --product MLAIXiOS
```

For iOS simulator or device, use Xcode: add the package and select the MLAIXiOS scheme. Or use `swift build` with the appropriate destination.

### tvOS
```bash
swift build --product MLAIXtvos
```

## iOS / iPadOS Notes

- **Remote API only**: Local llama-server inference is not available. Configure an OpenAI-compatible API endpoint (e.g. OpenAI, Together, Groq) in the setup screen.
- **Setup flow**: On first launch, enter your API base URL and key. Example: `https://api.openai.com/v1` with your OpenAI key.
- **Settings**: Use the gear icon to change API configuration.
- **Same binary**: The iOS build runs on both iPhone and iPad; layout adapts to screen size.

## Platform Minimums

All platforms require version 26:
- macOS 26
- iOS / iPadOS 26
- tvOS 26

## Shared Code (MLAIXShared)

The `MLAIXShared` library provides unified SwiftUI and SwiftData code across platforms:
- **SwiftData models**: `SharedChatMessage`, `SharedConversation` (with @Relationship)
- **Shared SwiftUI**: `SharedMessageBubble`, `SharedEmptyChatView`, `SharedLoadingIndicator`
- **Shared config**: `SharedAPIConfig` — API key in Keychain, URL/model in UserDefaults
- **Structured errors**: `SharedChatError` for API/network failures
- **Keychain**: `KeychainHelper` for secure storage

MLAIXiOS persists chat history via SwiftData and uses Keychain for API keys. SwiftData container initialization uses a file-based store first; if that fails (e.g. sandbox or permissions), it falls back to an in-memory store so the app can still run. On macOS, a one-time JSON→SwiftData migration runs for commands, inference records, server arguments, memories, and function selections; after that, the corresponding managers use SwiftData. Conversations on macOS remain JSON-backed.

## Testing

```bash
swift test                    # All tests (MLAIX + MLAIXiOS)
swift test --filter MLAIXiOSTests   # iOS-specific tests only
```
