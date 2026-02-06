//
//  Extension+View.swift
//  MLAIXShared
//
//  Platform-specific UI helpers for macOS, iOS, iPadOS.
//

import SwiftUI

public extension View {

    /// Applies the modifier only on macOS.
    @ViewBuilder
    func modifierForMacOS<Content: View>(@ViewBuilder _ modifier: (Self) -> Content) -> some View {
        #if os(macOS)
        modifier(self)
        #else
        self
        #endif
    }

    /// Applies the modifier only on iOS (including iPadOS).
    @ViewBuilder
    func modifierForIOS<Content: View>(@ViewBuilder _ modifier: (Self) -> Content) -> some View {
        #if os(iOS)
        modifier(self)
        #else
        self
        #endif
    }

    /// Uses `macOSContent` on macOS and `iOSContent` on iOS.
    @ViewBuilder
    func platformContent<MacContent: View, iOSContent: View>(
        macOS: (Self) -> MacContent,
        iOS: (Self) -> iOSContent
    ) -> some View {
        #if os(macOS)
        macOS(self)
        #else
        iOS(self)
        #endif
    }

    /// Applies tint only when a custom color is provided.
    func optionalTint(_ color: Color?) -> some View {
        modifier(OptionalTintModifier(color: color))
    }
}

public struct OptionalTintModifier: ViewModifier {
    let color: Color?
    public func body(content: Content) -> some View {
        if let color {
            content.tint(color)
        } else {
            content
        }
    }
}
