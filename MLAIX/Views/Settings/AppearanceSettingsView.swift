//
//  AppearanceSettingsView.swift
//  MLAI
//

import SwiftUI

struct AppearanceSettingsView: View {
    @AppStorage("appearanceMode") private var appearanceModeRaw: String = AppearanceSettings.AppearanceMode.system.rawValue
    @AppStorage("appearanceAccentHex") private var accentHex: String = ""
    @AppStorage("appearanceFontScale") private var fontScaleRaw: Double = AppearanceSettings.FontScale.default.rawValue
    @AppStorage("appearanceThemePreset") private var themePresetRaw: String = AppearanceSettings.ThemePreset.default.rawValue

    @AppStorage("appearanceLiquidGlassEnabled") private var liquidGlassEnabled: Bool = LiquidGlassStyle.default.isEnabled
    @AppStorage("appearanceGlassMaterial") private var glassMaterialRaw: String = LiquidGlassStyle.default.materialStyle.rawValue
    @AppStorage("appearanceTintHex") private var tintHex: String = LiquidGlassStyle.default.tintHex
    @AppStorage("appearanceHighlightHex") private var highlightHex: String = LiquidGlassStyle.default.highlightHex
    @AppStorage("appearanceGlassOpacity") private var glassOpacity: Double = LiquidGlassStyle.default.opacity
    @AppStorage("appearanceGlassCornerRadius") private var glassCornerRadius: Double = LiquidGlassStyle.default.cornerRadius

    private var appearanceModeBinding: Binding<AppearanceSettings.AppearanceMode> {
        Binding(
            get: { AppearanceSettings.AppearanceMode(rawValue: appearanceModeRaw) ?? .system },
            set: { appearanceModeRaw = $0.rawValue }
        )
    }

    private var fontScaleBinding: Binding<AppearanceSettings.FontScale> {
        Binding(
            get: { AppearanceSettings.FontScale(rawValue: fontScaleRaw) ?? .default },
            set: { fontScaleRaw = $0.rawValue }
        )
    }

    private var themePresetBinding: Binding<AppearanceSettings.ThemePreset> {
        Binding(
            get: { AppearanceSettings.ThemePreset(rawValue: themePresetRaw) ?? .default },
            set: {
                themePresetRaw = $0.rawValue
                tintHex = $0.tintHex
                highlightHex = $0.highlightHex
                if accentHex.isEmpty { accentHex = $0.accentHex }
            }
        )
    }

    private var tintBinding: Binding<Color> {
        Binding(
            get: { Color(hex: tintHex) },
            set: { if let h = $0.toHex { tintHex = h } }
        )
    }

    private var highlightBinding: Binding<Color> {
        Binding(
            get: { Color(hex: highlightHex) },
            set: { if let h = $0.toHex { highlightHex = h } }
        )
    }

    private var accentBinding: Binding<Color> {
        Binding(
            get: { accentHex.isEmpty ? Color.accentColor : Color(hex: accentHex) },
            set: {
                if let h = $0.toHex {
                    accentHex = h
                }
            }
        )
    }

    var body: some View {
        Form {
            themeSection
            accentSection
            layoutSection
            liquidGlassSection
        }
        .formStyle(.grouped)
    }

    private var themeSection: some View {
        Section {
            Picker("Appearance", selection: appearanceModeBinding) {
                ForEach(AppearanceSettings.AppearanceMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Picker("Theme Preset", selection: themePresetBinding) {
                ForEach(AppearanceSettings.ThemePreset.allCases) { preset in
                    HStack {
                        Circle()
                            .fill(Color(hex: preset.accentHex))
                            .frame(width: 12, height: 12)
                        Text(preset.displayName)
                    }
                    .tag(preset)
                }
            }
        } header: {
            Text("Theme")
        } footer: {
            Text("Presets apply tint and highlight colors. Customize further below.")
        }
    }

    private var accentSection: some View {
        Section {
            Toggle("Custom Accent Color", isOn: Binding(
                get: { !accentHex.isEmpty },
                set: { if !$0 { accentHex = "" } }
            ))
            if !accentHex.isEmpty {
                ColorPicker("Accent", selection: accentBinding, supportsOpacity: true)
            }
        } header: {
            Text("Accent")
        } footer: {
            Text("Accent color for buttons, links, and highlights. Turn off to use system accent.")
        }
    }

    private var layoutSection: some View {
        Section {
            Picker("Font Size", selection: fontScaleBinding) {
                ForEach(AppearanceSettings.FontScale.allCases) { scale in
                    Text(scale.displayName).tag(scale)
                }
            }
        } header: {
            Text("Layout")
        } footer: {
            Text("Adjust text size for readability.")
        }
    }

    private var liquidGlassSection: some View {
        Section {
            Toggle("Enable Liquid Glass", isOn: $liquidGlassEnabled.animation(.linear))
            Picker("Material", selection: $glassMaterialRaw) {
                ForEach(LiquidGlassStyle.MaterialStyle.allCases) { style in
                    Text(style.rawValue.capitalized).tag(style.rawValue)
                }
            }
            ColorPicker("Tint", selection: tintBinding, supportsOpacity: true)
            ColorPicker("Highlight", selection: highlightBinding, supportsOpacity: true)
            HStack {
                Text("Glass Opacity")
                Spacer()
                Slider(value: $glassOpacity, in: 0.0...1.0)
                    .frame(maxWidth: 200)
            }
            HStack {
                Text("Corner Radius")
                Spacer()
                Slider(value: $glassCornerRadius, in: 0...30)
                    .frame(maxWidth: 200)
            }
        } header: {
            Text("Liquid Glass")
        } footer: {
            Text("macOS 26 window and panel styling.")
        }
    }
}

#Preview {
    AppearanceSettingsView()
}
