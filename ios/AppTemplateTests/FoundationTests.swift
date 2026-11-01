import XCTest
import StoreKit
import UIKit
@testable import AppTemplate

@MainActor
final class FoundationTests: XCTestCase {
    enum Failure: Error { case expected }
    final class FakePurchases: PurchaseClient {
        var owned: [PremiumEntitlement] = []
        var fails = false
        var reads = 0
        var onRead: (() async -> Void)?
        func products(ids: [String]) async throws -> [Product] { [] }
        func entitlements() async throws -> [PremiumEntitlement] {
            reads += 1
            let snapshot = owned
            await onRead?()
            if fails { throw Failure.expected }
            return snapshot
        }
        func purchase(_ product: Product) async throws -> PremiumPurchaseOutcome { .cancelled }
        func restore() async throws { if fails { throw Failure.expected } }
        func updates() -> AsyncStream<Void> { AsyncStream { $0.finish() } }
    }
    func testExistingPurchaseIsLoadedAndFailedRefreshPreservesIt() async {
        let client = FakePurchases()
        client.owned = [.init(productID: AppConfig.premiumLifetimeProductID, expiresAt: nil, revoked: false)]
        let store = PremiumStore(client: client, analytics: .disabled)
        XCTAssertEqual(store.entitlementState, .unknown)
        await store.refreshEntitlements()
        XCTAssertTrue(store.isPremium)
        let checked = store.lastCheckedAt
        client.fails = true
        await store.refreshEntitlements()
        XCTAssertTrue(store.isPremium)
        XCTAssertEqual(store.lastCheckedAt, checked)
        XCTAssertEqual(store.entitlementState, .failed)
    }
    func testConfirmedEmptyAndRevokedSnapshotsRemoveAccess() async {
        let client = FakePurchases()
        let store = PremiumStore(client: client, analytics: .disabled)
        client.owned = [.init(productID: AppConfig.premiumLifetimeProductID, expiresAt: nil, revoked: false)]
        await store.refreshEntitlements()
        client.owned = [.init(productID: AppConfig.premiumLifetimeProductID, expiresAt: nil, revoked: true)]
        await store.refreshEntitlements()
        XCTAssertFalse(store.isPremium)
        client.owned = []
        await store.restorePurchases()
        XCTAssertEqual(store.entitlementState, .free)
        XCTAssertEqual(store.message, PremiumL10n.nothingToRestore)
    }
    func testKnownExpiryStillAppliesWhenRefreshFails() async {
        var date = Date(timeIntervalSince1970: 100)
        let client = FakePurchases()
        client.owned = [.init(productID: AppConfig.premiumMonthlyProductID, expiresAt: date.addingTimeInterval(1), revoked: false)]
        let store = PremiumStore(client: client, analytics: .disabled, now: { date })
        await store.refreshEntitlements()
        date = date.addingTimeInterval(2); client.fails = true
        await store.refreshEntitlements()
        XCTAssertFalse(store.isPremium)
    }
    func testConcurrentRefreshSharesOneRequest() async {
        let client = FakePurchases()
        client.onRead = { try? await Task.sleep(for: .milliseconds(30)) }
        let store = PremiumStore(client: client, analytics: .disabled)
        async let first: Void = store.refreshEntitlements()
        async let second: Void = store.refreshEntitlements()
        _ = await (first, second)
        XCTAssertEqual(client.reads, 1)
    }
    func testPurchaseUpdateDuringRefreshRequiresFreshSnapshot() async {
        let client = FakePurchases()
        client.onRead = { try? await Task.sleep(for: .milliseconds(30)) }
        let store = PremiumStore(client: client, analytics: .disabled)
        let initial = Task { await store.refreshEntitlements() }
        while client.reads == 0 { await Task.yield() }
        client.owned = [.init(productID: AppConfig.premiumLifetimeProductID, expiresAt: nil, revoked: false)]
        await store.refreshEntitlements(forceFresh: true)
        await initial.value
        XCTAssertTrue(store.isPremium)
        XCTAssertEqual(client.reads, 2)
    }
    func testRewardOutcomeIsDeliveredOnlyOnceAndOnlyAfterDismissal() {
        var results: [RewardedAdOutcome] = []
        let request = RewardAttempt { results.append($0) }
        request.earn()
        XCTAssertTrue(results.isEmpty)
        request.finish(); request.finish(failed: true)
        XCTAssertEqual(results, [.rewarded])
        RewardAttempt { results.append($0) }.finish()
        RewardAttempt { results.append($0) }.finish(failed: true)
        XCTAssertEqual(results, [.rewarded, .dismissed, .failed])
    }
    func testUnavailableDuplicateLoadFailureAndStaleAdCallbacks() {
        let gate = RewardGate()
        var first: [RewardedAdOutcome] = [], second: [RewardedAdOutcome] = []
        XCTAssertFalse(gate.begin(RewardAttempt { first.append($0) }, available: false))
        let loading = RewardAttempt { first.append($0) }
        XCTAssertTrue(gate.begin(loading, available: true))
        XCTAssertFalse(gate.begin(RewardAttempt { second.append($0) }, available: true))
        gate.finish(loading, failed: true) // load or presentation failure
        let next = RewardAttempt { second.append($0) }
        XCTAssertTrue(gate.begin(next, available: true))
        gate.finish(loading) // delayed callback from previous ad cannot finish next request
        XCTAssertTrue(gate.current === next)
        next.earn(); gate.finish(next); gate.finish(next)
        XCTAssertEqual(first, [.failed, .failed])
        XCTAssertEqual(second, [.failed, .rewarded])
    }
    func testReadFailureNeverBecomesFirstLaunchOrWrites() {
        var writes = 0
        let preferences = PreferencesClient(read: { _ in throw Failure.expected }, write: { _ in writes += 1 })
        let store = OnboardingStore(preferences: preferences, analytics: .disabled)
        XCTAssertEqual(store.loadState, .failed)
        store.complete(nickname: "Name")
        XCTAssertEqual(writes, 0)
    }
    func testWriteFailureDoesNotCompleteOnboardingOrTrack() {
        var events: [AppEvent] = []
        var fails = true
        var values: [String: Any] = [:]
        let preferences = PreferencesClient(read: { values[$0] }, write: {
            if fails { throw Failure.expected }; values.merge($0) { _, new in new }
        })
        let analytics = AnalyticsClient(track: { events.append($0) }, setNickname: { _ in })
        let store = OnboardingStore(preferences: preferences, analytics: analytics)
        store.complete(nickname: " Name ")
        XCTAssertFalse(store.hasCompletedOnboarding)
        XCTAssertTrue(store.saveFailed)
        XCTAssertTrue(events.isEmpty)
        fails = false; store.complete(nickname: " Name ")
        let reopened = OnboardingStore(preferences: preferences, analytics: .disabled)
        XCTAssertTrue(reopened.hasCompletedOnboarding)
        XCTAssertEqual(reopened.nickname, "Name")
        XCTAssertEqual(events, [.onboardingCompleted])
    }
    func testSettingsWriteFailureKeepsPreviousValueAndRetries() {
        var fails = true
        let preferences = PreferencesClient(read: { _ in nil }, write: { _ in if fails { throw Failure.expected } })
        let store = SettingsStore(preferences: preferences)
        store.setTheme(.dark)
        XCTAssertEqual(store.selectedTheme, .system)
        XCTAssertTrue(store.saveFailed)
        fails = false; store.retry()
        XCTAssertEqual(store.selectedTheme, .dark)
        XCTAssertFalse(store.saveFailed)
    }
    func testMalformedOnboardingValueIsNotSilentlyReset() {
        let preferences = PreferencesClient(read: { $0 == "onboarding.hasCompleted" ? "invalid" : nil }, write: { _ in XCTFail("must not overwrite") })
        let store = OnboardingStore(preferences: preferences, analytics: .disabled)
        XCTAssertEqual(store.loadState, .failed)
    }
    func testBundledFontsAndManifestExist() {
        for name in ["Pretendard-Bold", "Pretendard-SemiBold", "Pretendard-Medium", "Pretendard-Regular", "Pretendard-Light"] {
            XCTAssertNotNil(UIFont(name: name, size: 16), name)
        }
        XCTAssertNotNil(Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy"))
    }
}
