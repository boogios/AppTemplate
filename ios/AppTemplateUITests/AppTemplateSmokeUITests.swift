import XCTest

final class AppTemplateSmokeUITests: XCTestCase {
    func testSettingsSmokeFlowShowsCoreRows() {
        let app = XCUIApplication()
        app.launchArguments += [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "-complete-onboarding"
        ]
        app.launch()

        let settingsTab = app.tabBars.buttons.element(boundBy: 1)
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5))
        settingsTab.tap()

        XCTAssertTrue(app.buttons["settings.language"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["settings.theme"].exists)
        XCTAssertTrue(app.buttons["settings.developer-apps"].exists)
        XCTAssertTrue(app.buttons["settings.review"].exists)
        XCTAssertTrue(app.buttons["settings.support"].exists)
        XCTAssertTrue(app.buttons["settings.premium"].exists)
        XCTAssertFalse(app.buttons["settings.privacy-options"].exists)
        XCTAssertFalse(app.buttons["settings.notifications"].exists)

        app.buttons["settings.premium"].tap()
        XCTAssertTrue(app.buttons["premium.close"].waitForExistence(timeout: 3))
        app.buttons["premium.close"].tap()
    }

    func testFirstLaunchOnboardingReachesHome() {
        let app = XCUIApplication()
        app.launchArguments += [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "-reset-onboarding",
            "-ui-test-skip-permissions"
        ]
        addUIInterruptionMonitor(withDescription: "System permissions") { alert in
            if alert.buttons["Allow"].exists {
                alert.buttons["Allow"].tap()
                return true
            }
            if alert.buttons["허용"].exists {
                alert.buttons["허용"].tap()
                return true
            }
            if alert.buttons["OK"].exists {
                alert.buttons["OK"].tap()
                return true
            }
            return false
        }
        app.launch()

        XCTAssertTrue(app.buttons["onboarding.next"].waitForExistence(timeout: 5))
        app.buttons["onboarding.next"].tap()
        app.buttons["onboarding.next"].tap()
        XCTAssertTrue(app.textFields["onboarding.nickname"].waitForExistence(timeout: 3))
        app.textFields["onboarding.nickname"].tap()
        app.textFields["onboarding.nickname"].typeText("Boogi")
        app.buttons["onboarding.next"].tap()
        XCTAssertTrue(app.buttons["onboarding.next"].waitForExistence(timeout: 3))
        app.buttons["onboarding.next"].tap()

        let startButton = app.buttons["onboarding.start"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()
        XCTAssertTrue(app.tabBars.buttons.element(boundBy: 0).waitForExistence(timeout: 5))
    }

    func testSettingsCanReplayIntroOnly() {
        let app = XCUIApplication()
        app.launchArguments += [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "-complete-onboarding"
        ]
        app.launch()

        app.tabBars.buttons.element(boundBy: 1).tap()
        XCTAssertTrue(app.buttons["settings.replay-onboarding"].waitForExistence(timeout: 3))
        app.buttons["settings.replay-onboarding"].tap()

        XCTAssertTrue(app.buttons["onboarding.next"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.textFields["onboarding.nickname"].exists)
        app.buttons["onboarding.next"].tap()
        app.buttons["onboarding.start"].tap()
        XCTAssertTrue(app.tabBars.buttons.element(boundBy: 1).waitForExistence(timeout: 3))
    }
}
