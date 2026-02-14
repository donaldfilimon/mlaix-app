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
            liquidGlassPreview
            Picker("Color Preset", selection: liquidGlassPresetBinding) {
                Text("Custom").tag(nil as LiquidGlassStyle.ColorPreset?)
                ForEach(LiquidGlassStyle.ColorPreset.allCases) { preset in
                    HStack(spacing: 8) {
                        liquidGlassPresetSwatch(preset: preset)
                        Text(preset.displayName)
                    }
                    .tag(preset as LiquidGlassStyle.ColorPreset?)
                }
            }
            Picker("Material", selection: $glassMaterialRaw) {
                ForEach(LiquidGlassStyle.MaterialStyle.allCases) { style in
                    Text(style.displayName).tag(style.rawValue)
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
            Button("Reset Liquid Glass to Default") {
                liquidGlassEnabled = LiquidGlassStyle.default.isEnabled
                glassMaterialRaw = LiquidGlassStyle.default.materialStyle.rawValue
                tintHex = LiquidGlassStyle.default.tintHex
                highlightHex = LiquidGlassStyle.default.highlightHex
                glassOpacity = LiquidGlassStyle.default.opacity
                glassCornerRadius = LiquidGlassStyle.default.cornerRadius
            }
            .buttonStyle(.borderless)
        } header: {
            Text("Liquid Glass")
        } footer: {
            Text("Tint and highlight set the glass gradient. Presets apply both; use Custom and the color pickers to fine-tune.")
        }
    }

    private var liquidGlassPreview: some View {
        HStack(spacing: 12) {
            Text("Preview")
                .foregroundStyle(.secondary)
            RoundedRectangle(cornerRadius: min(glassCornerRadius, 12), style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: tintHex).opacity(glassOpacity),
                            Color(hex: highlightHex).opacity(glassOpacity * 0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: min(glassCornerRadius, 12), style: .continuous)
                        .stroke(Color(hex: highlightHex).opacity(0.3), lineWidth: 0.6)
                )
                .frame(width: 60, height: 36)
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func liquidGlassPresetSwatch(preset: LiquidGlassStyle.ColorPreset) -> some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(hex: preset.tintHex).opacity(0.9),
                        Color(hex: preset.highlightHex).opacity(0.7)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 20, height: 14)
    }

    private var liquidGlassPresetBinding: Binding<LiquidGlassStyle.ColorPreset?> {
        Binding(
            get: {
                LiquidGlassStyle.ColorPreset.allCases.first { preset in
                    preset.tintHex == tintHex && preset.highlightHex == highlightHex
                }
            },
            set: { newValue in
                if let preset = newValue {
                    tintHex = preset.tintHex
                    highlightHex = preset.highlightHex
                }
            }
        )
    }
}

#Preview {
    AppearanceSettingsView()
}
