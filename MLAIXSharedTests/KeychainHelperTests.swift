//
//  KeychainHelperTests.swift
//  MLAIXSharedTests
//

import Foundation
import Testing
@testable import MLAIXShared

struct KeychainHelperTests {

    @Test func testSetAndGet() {
        let key = "test_key_\(UUID().uuidString)"
        KeychainHelper.set(key: key, value: "secret123")
        #expect(KeychainHelper.get(key: key) == "secret123")
        KeychainHelper.delete(key: key)
    }

    @Test func testDeleteRemovesValue() {
        let key = "test_key_\(UUID().uuidString)"
        KeychainHelper.set(key: key, value: "secret")
        KeychainHelper.delete(key: key)
        #expect(KeychainHelper.get(key: key) == nil)
    }

    @Test func testSetNilRemovesValue() {
        let key = "test_key_\(UUID().uuidString)"
        KeychainHelper.set(key: key, value: "secret")
        KeychainHelper.set(key: key, value: nil)
        #expect(KeychainHelper.get(key: key) == nil)
    }
}
