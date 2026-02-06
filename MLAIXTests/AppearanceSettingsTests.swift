//
//  AppearanceSettingsTests.swift
//  MLAIXTests
//

import SwiftUI
import Testing
@testable import MLAIX

struct AppearanceSettingsTests {

    @Test func testAppearanceModeAllCases() {
        #expect(AppearanceSettings.AppearanceMode.allCases.count == 3)
    }

    @Test func testAppearanceModeColorScheme() {
        #expect(AppearanceSettings.AppearanceMode.system.colorScheme == nil)
        #expect(AppearanceSettings.AppearanceMode.light.colorScheme == .light)
        #expect(AppearanceSettings.AppearanceMode.dark.colorScheme == .dark)
    }

    @Test func testAppearanceModeDisplayNames() {
        #expect(AppearanceSettings.AppearanceMode.system.displayName == "System")
        #expect(AppearanceSettings.AppearanceMode.light.displayName == "Light")
        #expect(AppearanceSettings.AppearanceMode.dark.displayName == "Dark")
    }

    @Test func testFontScaleAllCases() {
        #expect(AppearanceSettings.FontScale.allCases.count == 3)
    }

    @Test func testFontScaleRawValues() {
        #expect(AppearanceSettings.FontScale.compact.rawValue == 0.9)
        #expect(AppearanceSettings.FontScale.default.rawValue == 1.0)
        #expect(AppearanceSettings.FontScale.large.rawValue == 1.15)
    }

    @Test func testFontScaleDisplayNames() {
        #expect(AppearanceSettings.FontScale.compact.displayName == "Compact")
        #expect(AppearanceSettings.FontScale.default.displayName == "Default")
        #expect(AppearanceSettings.FontScale.large.displayName == "Large")
    }

    @Test func testThemePresetAllCases() {
        #expect(AppearanceSettings.ThemePreset.allCases.count == 6)
    }

    @Test func testThemePresetTintAndHighlightHexFormat() {
        for preset in AppearanceSettings.ThemePreset.allCases {
            #expect(preset.tintHex.count == 8)
            #expect(preset.highlightHex.count == 8)
            #expect(preset.accentHex.count == 8)
        }
    }

    @Test func testAppearanceSettingsDefault() {
        let settings = AppearanceSettings.default
        #expect(settings.appearanceMode == .system)
        #expect(settings.accentColorHex == nil)
        #expect(settings.fontScale == .default)
        #expect(settings.themePreset == .default)
        #expect(settings.effectiveFontScale == 1.0)
    }

    @Test func testAppearanceSettingsResolvedAccentNilWhenEmpty() {
        var settings = AppearanceSettings.default
        settings.accentColorHex = nil
        #expect(settings.resolvedAccentColor == nil)
    }
}
