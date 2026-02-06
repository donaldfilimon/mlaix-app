//
//  ColorHexTests.swift
//  MLAIXSharedTests
//

import SwiftUI
import Testing
@testable import MLAIXShared

struct ColorHexTests {

    @Test func testColorHexParses8CharRRGGBBAA() {
        let c = Color(hex: "FF0000FF")
        #expect(c != Color.clear)
    }

    @Test func testColorHexParses6CharRGB() {
        let c = Color(hex: "FF0000")
        #expect(c != Color.clear)
    }

    @Test func testColorHexParsesWithHash() {
        let c = Color(hex: "#00FF00FF")
        #expect(c != Color.clear)
    }

    @Test func testColorHexInvalidDoesNotCrash() {
        let c = Color(hex: "xyz")
        #expect(c != Color.clear)
    }

    @Test func testColorHexRoundTripProducesValidHex() {
        let hex = "101828FF"
        let c = Color(hex: hex)
        let roundTripped = c.toHex
        #expect(roundTripped != nil)
        #expect(roundTripped!.count == 8)
        #expect(roundTripped!.allSatisfy { $0.isHexDigit })
    }

    @Test func testColorHexParsesWhite() {
        let c = Color(hex: "FFFFFFFF")
        let h = c.toHex
        #expect(h != nil)
        #expect(h!.uppercased() == "FFFFFFFF")
    }

    @Test func testColorHexParsesBlack() {
        let c = Color(hex: "000000FF")
        let h = c.toHex
        #expect(h != nil)
        #expect(h!.uppercased() == "000000FF")
    }
}
