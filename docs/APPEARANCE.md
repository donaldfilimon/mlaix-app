# Appearance Customization

MLAIX supports user-customizable appearance on both macOS and iOS.

## macOS

**Settings → Appearance** provides:

### Theme
- **Appearance**: System, Light, or Dark
- **Theme Preset**: Default, Ocean, Forest, Sunset, Lavender, Rose — quick-apply tint and highlight colors

### Accent
- **Custom Accent Color**: Override system accent for buttons, links, and highlights
- Turn off to use the system accent color

### Layout
- **Font Size**: Compact (0.9×), Default (1×), Large (1.15×)

### Liquid Glass (macOS 26)
- **Enable Liquid Glass**: Window and panel styling
- **Material**: Ultra thin, thin, regular, thick, ultra thick
- **Tint** / **Highlight**: Color pickers for glass gradient
- **Glass Opacity** / **Corner Radius**: Sliders

## iOS

**Settings → Appearance** provides:

### Theme
- **Appearance**: System, Light, or Dark
- **Theme Preset**: Same presets as macOS (Default, Ocean, Forest, Sunset, Lavender, Rose)

### Accent
- **Custom Accent Color**: Override system accent
- Presets set accent automatically; toggle off to use system

### Layout
- **Font Size**: Compact, Default, Large

## Shared Settings

`appearanceMode`, `appearanceAccentHex`, `appearanceFontScale`, and `appearanceThemePreset` are stored in `UserDefaults` with the same keys on both platforms. If you use MLAIX on Mac and iPhone, settings stay in sync when both apps are installed (per-device storage; no cloud sync).

## Implementation

- **AppearanceSettings** (macOS): `MLAIX/Types/Appearance/AppearanceSettings.swift`
- **ThemePreset** (shared): `MLAIXShared/Types/ThemePreset.swift`
- **Color hex**: `MLAIXShared/Extensions/Extension+Color.swift` — `Color(hex:)`, `toHex`
- **OptionalTintModifier**: `MLAIXShared/Extensions/Extension+View.swift`
- **FontScaleModifier** (macOS): `MLAIX/Extensions/UI/Extension+View.swift`

## Tests

- **AppearanceSettingsTests** — Appearance mode, font scale, theme presets
- **ThemePresetTests** — Preset enum, accent hex format
- **ColorHexTests** — Hex parsing, round-trip
