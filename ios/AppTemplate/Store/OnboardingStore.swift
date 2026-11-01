import Foundation
import SwiftUI

@MainActor
final class OnboardingStore: ObservableObject {
    @Published private(set) var hasCompletedOnboarding = false
    @Published private(set) var nickname = ""
    @Published private(set) var loadState: LoadState = .loading
    @Published private(set) var saveFailed = false
    @Published var isReplayPresented = false
    private let preferences: PreferencesClient
    private let analytics: AnalyticsClient

    convenience init(userDefaults: UserDefaults = .standard) {
        self.init(preferences: .defaults(userDefaults), analytics: .live)
    }
    init(preferences: PreferencesClient, analytics: AnalyticsClient) {
        self.preferences = preferences; self.analytics = analytics
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-reset-onboarding") {
            try? preferences.write([Keys.completed: false, Keys.nickname: ""])
        }
        if ProcessInfo.processInfo.arguments.contains("-complete-onboarding") {
            try? preferences.write([Keys.completed: true, Keys.nickname: "Test User"])
        }
        #endif
        reload()
    }
    func reload() {
        loadState = .loading
        do {
            let value = try preferences.read(Keys.completed)
            guard value == nil || value is Bool else { throw PreferencesClient.PreferenceError.invalidValue }
            let name = try preferences.string(Keys.nickname)
            nickname = name; hasCompletedOnboarding = value as? Bool ?? false
            loadState = .ready
        } catch { loadState = .failed }
    }
    func complete(nickname: String) {
        guard loadState == .ready else { return }
        let value = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Self.isValidNickname(value) else { return }
        do {
            try preferences.write([Keys.nickname: value, Keys.completed: true])
            self.nickname = value; hasCompletedOnboarding = true; saveFailed = false
            analytics.setNickname(value); analytics.track(.onboardingCompleted)
        } catch { saveFailed = true }
    }
    func presentReplay() { isReplayPresented = true; analytics.track(.onboardingReplayed) }
    func dismissReplay() { isReplayPresented = false }
    static func isValidNickname(_ value: String) -> Bool { (1...20).contains(value.trimmingCharacters(in: .whitespacesAndNewlines).count) }
    private enum Keys {
        static let completed = "onboarding.hasCompleted"
        static let nickname = "onboarding.nickname"
    }
}
