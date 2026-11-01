import Foundation
import SwiftUI
import UIKit

/// No SDK traffic from previews, unit tests, or explicitly isolated UI tests.
enum AppRuntime {
    static var isIsolated: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
            || ProcessInfo.processInfo.arguments.contains("-ui-testing")
            || NSClassFromString("XCTestCase") != nil
    }
}

enum LoadState: Equatable { case loading, ready, empty, failed }
enum EntitlementState: Equatable { case unknown, checking, free, premium, failed }
enum RewardedAdOutcome: String { case rewarded, dismissed, failed }

enum AppEvent: String, CaseIterable {
    case onboardingCompleted = "onboarding_completed"
    case onboardingReplayed = "onboarding_replayed"
    case premiumViewed = "premium_viewed"
    case purchaseStarted = "purchase_started"
    case purchaseCompleted = "purchase_completed"
    case purchasePending = "purchase_pending"
    case purchaseCancelled = "purchase_cancelled"
    case purchaseFailed = "purchase_failed"
    case purchaseRestored = "purchase_restored"
    case rewardedAdRequested = "rewarded_ad_requested"
    case rewardedAdCompleted = "rewarded_ad_completed"
    case rewardedAdDismissed = "rewarded_ad_dismissed"
    case rewardedAdFailed = "rewarded_ad_failed"
}

@MainActor
struct AnalyticsClient {
    var track: (AppEvent) -> Void
    var setNickname: (String) -> Void
    static let disabled = Self(track: { _ in }, setNickname: { _ in })
    static var live: Self {
        guard !AppRuntime.isIsolated else { return .disabled }
        return Self(track: { MixpanelManager.shared.track(event: $0.rawValue) },
                    setNickname: { MixpanelManager.shared.setUserProperties(nickname: $0) })
    }
}

@MainActor
struct PreferencesClient {
    var read: (String) throws -> Any?
    var write: ([String: Any]) throws -> Void

    static func defaults(_ defaults: UserDefaults) -> Self {
        Self(read: { defaults.object(forKey: $0) }, write: { values in
            // UserDefaults owns disk persistence; this adapter acknowledges its in-process write.
            values.forEach { defaults.set($0.value, forKey: $0.key) }
        })
    }
    static func memory() -> Self {
        var values: [String: Any] = [:]
        return Self(read: { values[$0] }, write: { values.merge($0) { _, new in new } })
    }
    func string(_ key: String, fallback: String = "") throws -> String {
        guard let value = try read(key) else { return fallback }
        guard let string = value as? String else { throw PreferenceError.invalidValue }
        return string
    }
    enum PreferenceError: Error { case invalidValue }
}

@MainActor
struct PermissionClient {
    var notifications: () async -> Void
    var advertising: () async -> Void
    static let disabled = Self(notifications: {}, advertising: {})
    static var live: Self {
        guard !AppRuntime.isIsolated else { return .disabled }
        return Self(notifications: { await NotificationAuthorizationManager.shared.requestIfNeeded() },
                    advertising: {
            await AdMobManager.shared.requestConsentForOnboarding()
            await TrackingAuthorizationManager.shared.requestIfNeeded()
        })
    }
}

@MainActor
struct AdvertisingClient {
    var start: () -> Void
    var reward: (String, UIViewController, @escaping (RewardedAdOutcome) -> Void) -> Void
    static let disabled = Self(start: {}, reward: { _, _, completion in completion(.failed) })
    static var live: Self {
        guard !AppRuntime.isIsolated else { return .disabled }
        return Self(start: { AdMobManager.shared.startIfConfigured() }, reward: { id, controller, completion in
            RewardedAdService.shared.present(adUnitID: id, from: controller, completion: completion)
        })
    }
}

private struct AdvertisingClientKey: EnvironmentKey {
    static let defaultValue: AdvertisingClient? = nil
}
extension EnvironmentValues {
    var advertisingClient: AdvertisingClient? {
        get { self[AdvertisingClientKey.self] }
        set { self[AdvertisingClientKey.self] = newValue }
    }
}

@MainActor
struct AppDependencies {
    var preferences: PreferencesClient
    var purchases: any PurchaseClient
    var analytics: AnalyticsClient
    var permissions: PermissionClient
    var advertising: AdvertisingClient
    static var live: Self {
        Self(preferences: .defaults(.standard),
             purchases: AppRuntime.isIsolated ? PreviewPurchaseClient() : StoreKitPurchaseClient(),
             analytics: .live, permissions: .live, advertising: .live)
    }
    static var preview: Self {
        Self(preferences: .memory(), purchases: PreviewPurchaseClient(), analytics: .disabled, permissions: .disabled, advertising: .disabled)
    }
}

@MainActor
final class AppCoordinator: ObservableObject {
    let settings: SettingsStore
    let onboarding: OnboardingStore
    let premium: PremiumStore
    let dependencies: AppDependencies
    private var preparing = false

    init(dependencies: AppDependencies? = nil) {
        let dependencies = dependencies ?? .live
        self.dependencies = dependencies
        settings = SettingsStore(preferences: dependencies.preferences)
        onboarding = OnboardingStore(preferences: dependencies.preferences, analytics: dependencies.analytics)
        premium = PremiumStore(client: dependencies.purchases, analytics: dependencies.analytics)
    }
    func prepare() async {
        guard !preparing else { return }
        preparing = true
        defer { preparing = false }
        if !AppRuntime.isIsolated { MixpanelManager.shared.initializeIfConfigured() }
        await premium.refreshEntitlements()
    }
}

/// Preview owns its isolated objects for its entire lifetime.
struct AppPreview<Content: View>: View {
    @StateObject private var coordinator = AppCoordinator(dependencies: .preview)
    @StateObject private var appStore = AppStore()
    @StateObject private var navigation = NavigationPathManager()
    @ViewBuilder var content: () -> Content
    var body: some View {
        content().environment(\.advertisingClient, coordinator.dependencies.advertising).environmentObject(coordinator.settings).environmentObject(coordinator.onboarding)
            .environmentObject(coordinator.premium).environmentObject(appStore).environmentObject(navigation)
    }
}
