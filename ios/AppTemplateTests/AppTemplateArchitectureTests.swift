import SwiftUI
import XCTest
@testable import AppTemplate

final class AppTemplateArchitectureTests: XCTestCase {
    func testAppStoreStartsOnHomeTab() {
        XCTAssertEqual(AppStore().selectedTab, .home)
    }

    func testThemeMapsToExpectedColorScheme() {
        XCTAssertNil(AppTheme.system.colorScheme)
        XCTAssertEqual(AppTheme.light.colorScheme, .light)
        XCTAssertEqual(AppTheme.dark.colorScheme, .dark)
    }

    func testRequiredLanguagesRemainAvailable() {
        let requiredLanguages: [AppLanguage] = [
            .system,
            .korean,
            .japanese,
            .englishUS,
            .englishGB,
            .englishCA,
            .englishAU,
            .german,
            .french,
            .portugueseBR,
            .vietnamese,
        ]

        XCTAssertEqual(
            Set(AppLanguage.displayCases.map(\.rawValue)),
            Set(requiredLanguages.map(\.rawValue))
        )
    }

    func testDeveloperAppsURLIsConfigured() {
        XCTAssertEqual(
            AppConfig.developerAppsURL.absoluteString,
            "https://boogios-studio.vercel.app/"
        )
    }

    func testSettingsMenuIncludesSystemReviewRequest() {
        let reviewItem = SettingMenu.make(
            version: "1.0.0",
            language: .system,
            theme: .system,
            isPrivacyOptionsRequired: false
        )
        .flatMap(\.items)
        .first { $0.accessibilityIdentifier == "settings.review" }

        guard let reviewItem else {
            XCTFail("The settings menu should include a review request row")
            return
        }

        if case .requestReview = reviewItem.action {
            return
        }
        XCTFail("The review row should use the system review request action")
    }

    func testPremiumProductIDsAreConfiguredForTemplateReplacement() {
        XCTAssertEqual(
            PremiumConfiguration.productIDs,
            [
                "com.boogios.template.premium.monthly",
                "com.boogios.template.premium.yearly",
                "com.boogios.template.premium.lifetime"
            ]
        )
    }

    @MainActor
    func testOnboardingDefaultsToIncompleteAndValidatesNickname() {
        let suiteName = "AppTemplateTests.OnboardingStore"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = OnboardingStore(userDefaults: defaults)

        XCTAssertFalse(store.hasCompletedOnboarding)
        XCTAssertTrue(OnboardingStore.isValidNickname("Boogi"))
        XCTAssertEqual("Boogi", "  Boogi  ".trimmingCharacters(in: .whitespacesAndNewlines))
        XCTAssertFalse(OnboardingStore.isValidNickname(""))
        XCTAssertFalse(OnboardingStore.isValidNickname(String(repeating: "a", count: 21)))

        store.complete(nickname: "  Boogi  ")

        XCTAssertTrue(store.hasCompletedOnboarding)
        XCTAssertEqual(store.nickname, "Boogi")
        XCTAssertEqual(defaults.string(forKey: "onboarding.nickname"), "Boogi")
    }

    @MainActor
    func testReplayKeepsCompletedStateAndNickname() {
        let suiteName = "AppTemplateTests.OnboardingReplayStore"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = OnboardingStore(userDefaults: defaults)
        store.complete(nickname: "Boogi")

        store.presentReplay()

        XCTAssertTrue(store.hasCompletedOnboarding)
        XCTAssertEqual(store.nickname, "Boogi")
        XCTAssertTrue(store.isReplayPresented)
        store.dismissReplay()
        XCTAssertFalse(store.isReplayPresented)
    }

    @MainActor
    func testPlaceholderAdMobSkipsPrivacyRequests() async {
        XCTAssertFalse(AppConfig.hasAdMobConfiguration)

        await AdMobManager.shared.requestConsentForOnboarding()
        await TrackingAuthorizationManager.shared.requestIfNeeded()

        XCTAssertFalse(AdMobManager.shared.canRequestAds)
    }
}
