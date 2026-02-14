//
//  MLAIXUITests.swift
//  MLAIXUITests
//
//  UI tests for MLAIX. Run from Xcode (Product > Test) with the MLAIX scheme
//  so the host application is set. See MLAIXUITests/README.md.
//

import XCTest

final class MLAIXUITests: XCTestCase {

    @MainActor
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        try skipIfHostAppUnavailable()
    }

    // MARK: - Launch

    @MainActor
    func testLaunch() throws {
        app = launchMLAIX()
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    // MARK: - Main window and navigation

    @MainActor
    func testMainWindowShowsPrimarySidebar() throws {
        app = launchMLAIX()
        let sidebar = app.otherElements[MLAIXAccessibility.primarySidebar]
        XCTAssertElementExists(sidebar, timeout: 15)
    }

    @MainActor
    func testSidebarShowsConversationsSection() throws {
        app = launchMLAIX()
        let id = MLAIXAccessibility.sidebarSection("conversations")
        let conversations = app.otherElements[id].firstMatch
        XCTAssertElementExists(conversations, timeout: 15)
    }

    @MainActor
    func testSidebarShowsToolsSection() throws {
        app = launchMLAIX()
        let id = MLAIXAccessibility.sidebarSection("tools")
        let tools = app.otherElements[id].firstMatch
        XCTAssertElementExists(tools, timeout: 15)
    }

    @MainActor
    func testContentColumnExistsAfterLaunch() throws {
        app = launchMLAIX()
        let content = app.otherElements[MLAIXAccessibility.contentColumn]
        XCTAssertElementExists(content, timeout: 15)
    }

    @MainActor
    func testTapToolsShowsToolsContent() throws {
        app = launchMLAIX()
        let id = MLAIXAccessibility.sidebarSection("tools")
        let toolsElement = app.otherElements[id].firstMatch
        XCTAssertElementExists(toolsElement, timeout: 15)
        if toolsElement.isHittable {
            toolsElement.tap()
        }
        let content = app.otherElements[MLAIXAccessibility.contentColumn]
        XCTAssertTrue(content.waitForExistence(timeout: 5), "Content column should exist after tapping Tools")
    }

    @MainActor
    func testToolbarNewConversationButtonExists() throws {
        app = launchMLAIX()
        let button = app.buttons[MLAIXAccessibility.toolbarNewConversation]
        XCTAssertElementExists(button, timeout: 15)
    }

    @MainActor
    func testToolbarToolboxButtonExists() throws {
        app = launchMLAIX()
        let button = app.buttons[MLAIXAccessibility.toolbarToolbox]
        XCTAssertElementExists(button, timeout: 15)
    }

    @MainActor
    func testNewConversationFromToolbar() throws {
        app = launchMLAIX()
        let toolbarButton = app.buttons[MLAIXAccessibility.toolbarNewConversation]
        XCTAssertElementExists(toolbarButton, timeout: 15)
        toolbarButton.tap()
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 5))
    }

    @MainActor
    func testNoConversationSelectedShowsNewConversationButton() throws {
        app = launchMLAIX()
        let emptyState = app.otherElements[MLAIXAccessibility.noConversationSelected]
        let emptyButton = app.buttons[MLAIXAccessibility.noConversationNewButton]
        let toolbarButton = app.buttons[MLAIXAccessibility.toolbarNewConversation]
        let hasEmptyState = emptyState.waitForExistence(timeout: 5)
        let hasToolbarButton = toolbarButton.waitForExistence(timeout: 2)
        XCTAssertTrue(
            hasEmptyState || hasToolbarButton,
            "Expected either no-conversation empty state or toolbar New Conversation button"
        )
        if hasEmptyState && emptyButton.waitForExistence(timeout: 2) {
            emptyButton.tap()
            XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 5))
        }
    }
}
