//
//  AppearanceSettingsView.swift
//  MLAI
//
//  Created by Codex on 2/5/26.
//

import SwiftUI

struct AppearanceSettingsView: View {
    
    @AppStorage("appearanceLiquidGlassEnabled") private var liquidGlassEnabled: Bool = LiquidGlassStyle.default.isEnabled
    @AppStorage("appearanceGlassMaterial") private var glassMaterialRaw: String = LiquidGlassStyle.default.materialStyle.rawValue
    @AppStorage("appearanceTintHex") private var tintHex: String = LiquidGlassStyle.default.tintHex
    @AppStorage("appearanceHighlightHex") private var highlightHex: String = LiquidGlassStyle.default.highlightHex
    @AppStorage("appearanceGlassOpacity") private var glassOpacity: Double = LiquidGlassStyle.default.opacity
    @AppStorage("appearanceGlassCornerRadius") private var glassCornerRadius: Double = LiquidGlassStyle.default.cornerRadius
    
    private var materialStyle: LiquidGlassStyle.MaterialStyle {
        LiquidGlassStyle.MaterialStyle(rawValue: glassMaterialRaw) ?? .ultraThin
    }
    
    private var tintBinding: Binding<Color> {
        Binding(
            get: { Color(hex: tintHex) },
            set: { newValue in
                if let hex = newValue.toHex {
                    tintHex = hex
                }
            }
        )
    }
    
    private var highlightBinding: Binding<Color> {
        Binding(
            get: { Color(hex: highlightHex) },
            set: { newValue in
                if let hex = newValue.toHex {
                    highlightHex = hex
                }
            }
        )
    }
    
    var body: some View {
        Form {
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
                Text("Appearance")
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    AppearanceSettingsView()
}
