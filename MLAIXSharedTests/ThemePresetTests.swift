//
//  ThemePresetTests.swift
//  MLAIXSharedTests
//

import SwiftUI
import Testing
@testable import MLAIXShared

struct ThemePresetTests {

    @Test func testThemePresetAllCases() {
        #expect(ThemePreset.allCases.count == 6)
    }

    @Test func testThemePresetIdsMatchRawValues() {
        for preset in ThemePreset.allCases {
            #expect(preset.id == preset.rawValue)
        }
    }

    @Test func testThemePresetDisplayNamesNonEmpty() {
        for preset in ThemePreset.allCases {
            #expect(!preset.displayName.isEmpty)
        }
    }

    @Test func testThemePresetAccentHexFormat() {
        for preset in ThemePreset.allCases {
            let hex = preset.accentHex
            #expect(hex.count == 8, "accentHex must be 8 chars (RRGGBBAA)")
            #expect(hex.allSatisfy { $0.isHexDigit })
        }
    }

    @Test func testThemePresetDefaultValues() {
        #expect(ThemePreset.default.displayName == "Default")
        #expect(ThemePreset.default.accentHex == "007AFFFF")
    }

    @Test func testThemePresetFromRawValue() {
        #expect(ThemePreset(rawValue: "ocean") == .ocean)
        #expect(ThemePreset(rawValue: "invalid") == nil)
    }
}
