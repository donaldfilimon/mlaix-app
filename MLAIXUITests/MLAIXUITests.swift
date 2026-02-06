//
//  MLAIXUITests.swift
//  MLAIXUITests
//
//  UI tests for MLAIX. Run from Xcode (Product > Test) or:
//  swift test --filter MLAIXUITests
//
//  Note: XCUI tests require the app to be built as a host. When run via
//  swift test, launch may fail if the app bundle is not found.
//

import XCTest

final class MLAIXUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
