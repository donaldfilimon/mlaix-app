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
        try skipIfHostAppUnavailable()
    }

    @MainActor
    func testLaunchScreenshot() throws {
        let app = launchMLAIX(timeout: 15)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "MLAIX Launch"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testMainWindowScreenshotAfterLaunch() throws {
        let app = launchMLAIX(timeout: 15)
        _ = app.otherElements[MLAIXAccessibility.primarySidebar].waitForExistence(timeout: 10)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "MLAIX Main Window"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
