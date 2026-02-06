//
//  MLAIXUITestsLaunchTests.swift
//  MLAIXUITests
//
//  Launch and screenshot tests for MLAIX.
//

import XCTest

final class MLAIXUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchScreenshot() throws {
        let app = XCUIApplication()
        app.launch()

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "MLAIX Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
