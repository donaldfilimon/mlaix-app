//
//  MLAIXUITestHelpers.swift
//  MLAIXUITests
//
//  Helpers for XCUI tests: launch configuration, waits, and common queries.
//

import XCTest

/// Default timeout for UI elements to appear (seconds).
let defaultUITimeout: TimeInterval = 15

/// When set to "1", UI tests run (e.g. from Xcode with MLAIX as host). When unset, tests skip so `swift test` passes.
let uiTestHostAvailableEnvKey = "MLAIX_UI_TEST_HOST_AVAILABLE"

/// Throws `XCTSkip` when no host app is configured (e.g. running via `swift test`). Call from setUp or test body.
func skipIfHostAppUnavailable() throws {
    guard ProcessInfo.processInfo.environment[uiTestHostAvailableEnvKey] == "1" else {
        throw XCTSkip("UI tests require host app. Run from Xcode with MLAIX as host and \(uiTestHostAvailableEnvKey)=1 in the scheme.")
    }
}

/// Launch and wait for the app to be running in the foreground.
/// Use launchArguments or launchEnvironment to skip setup or enable test mode if the app supports it.
@MainActor
func launchMLAIX(
    arguments: [String] = [],
    environment: [String: String] = [:],
    timeout: TimeInterval = defaultUITimeout
) -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = arguments
    app.launchEnvironment.merge(environment) { _, new in new }
    app.launch()
    XCTAssertTrue(
        app.wait(for: .runningForeground, timeout: timeout),
        "App should be running in foreground within \(timeout)s"
    )
    return app
}

/// Wait for an element to exist and be hittable; returns the element or nil.
@MainActor
func waitForElement(
    _ element: XCUIElement,
    timeout: TimeInterval = defaultUITimeout
) -> XCUIElement? {
    let predicate = NSPredicate(format: "exists == true AND isHittable == true")
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
    let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
    return (result == .completed) ? element : nil
}

/// Assert that an element exists (and optionally is hittable) within the timeout.
@MainActor
func XCTAssertElementExists(
    _ element: XCUIElement,
    timeout: TimeInterval = defaultUITimeout,
    requireHittable: Bool = true,
    file: StaticString = #file,
    line: UInt = #line
) {
    let predicate = requireHittable
        ? NSPredicate(format: "exists == true AND isHittable == true")
        : NSPredicate(format: "exists == true")
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
    let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
    XCTAssertTrue(
        result == .completed,
        "Expected element to exist\(requireHittable ? " and be hittable" : "") within \(timeout)s",
        file: (file),
        line: line
    )
}

/// Accessibility identifiers used by the app (mirror app constants for stability).
enum MLAIXAccessibility {
    static let primarySidebar = "primarySidebar"
    static func sidebarSection(_ section: String) -> String { "sidebar.\(section)" }
    static let contentColumn = "contentColumn"
    static let newConversationButton = "newConversationButton"
    static let toolbarNewConversation = "toolbar.newConversation"
    static let toolbarToolbox = "toolbar.toolbox"
    static let noConversationSelected = "noConversationSelected"
    static let noConversationNewButton = "noConversation.newConversationButton"
}
