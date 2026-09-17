//
//  OnboardingStore.swift
//  AppTemplate
//

import Foundation
import SwiftUI

@MainActor
final class OnboardingStore: ObservableObject {

    @Published private(set) var hasCompletedOnboarding: Bool
    @Published private(set) var nickname: String
    @Published var isReplayPresented = false

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        if ProcessInfo.processInfo.arguments.contains("-reset-onboarding") {
            userDefaults.removeObject(forKey: Keys.hasCompletedOnboarding)
            userDefaults.removeObject(forKey: Keys.nickname)
        }

        if ProcessInfo.processInfo.arguments.contains("-complete-onboarding") {
            userDefaults.set(true, forKey: Keys.hasCompletedOnboarding)
            userDefaults.set("Test User", forKey: Keys.nickname)
        }

        hasCompletedOnboarding = userDefaults.bool(forKey: Keys.hasCompletedOnboarding)
        nickname = userDefaults.string(forKey: Keys.nickname) ?? ""
    }

    func complete(nickname: String) {
        let trimmedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Self.isValidNickname(trimmedNickname) else { return }

        self.nickname = trimmedNickname
        hasCompletedOnboarding = true
        userDefaults.set(trimmedNickname, forKey: Keys.nickname)
        userDefaults.set(true, forKey: Keys.hasCompletedOnboarding)

        MixpanelManager.shared.setUserProperties(nickname: trimmedNickname)
        MixpanelManager.shared.track(event: "onboarding_completed")
    }

    func presentReplay() {
        isReplayPresented = true
        MixpanelManager.shared.track(event: "onboarding_replayed")
    }

    func dismissReplay() {
        isReplayPresented = false
    }

    static func isValidNickname(_ nickname: String) -> Bool {
        let trimmedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        return (1...20).contains(trimmedNickname.count)
    }

    private enum Keys {
        static let hasCompletedOnboarding = "onboarding.hasCompleted"
        static let nickname = "onboarding.nickname"
    }
}
