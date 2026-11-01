import XCTest
import StoreKit
import StoreKitTest
@testable import AppTemplate

/// Runs serially against Xcode's local store, never the App Store sandbox.
@MainActor
final class StoreKitLocalTests: XCTestCase {
    private func waitForAccess(_ expected: Bool, store: PremiumStore) async {
        for _ in 0..<30 {
            await store.refreshEntitlements()
            if store.isPremium == expected { return }
            try? await Task.sleep(for: .milliseconds(100))
        }
    }
    func testProductsPurchaseRelaunchRestoreRefundAndExpiration() async throws {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "TemplateProducts", withExtension: "storekit"))
        let session = try SKTestSession(contentsOf: url)
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true
        defer { session.clearTransactions() }
        let store = PremiumStore(client: StoreKitPurchaseClient(), analytics: .disabled)
        print("LocalStore: load products")
        await store.loadProducts()
        XCTAssertEqual(Set(store.products.map(\.id)), Set(PremiumConfiguration.productIDs))
        let lifetime = try XCTUnwrap(store.product(for: AppConfig.premiumLifetimeProductID))
        print("LocalStore: purchase")
        let result = await store.purchase(lifetime)
        XCTAssertEqual(result, .purchased)
        XCTAssertTrue(store.isPremium)

        let reopened = PremiumStore(client: StoreKitPurchaseClient(), analytics: .disabled)
        await waitForAccess(true, store: reopened)
        XCTAssertTrue(reopened.isPremium)
        print("LocalStore: restore")
        await reopened.restorePurchases()
        XCTAssertTrue(reopened.isPremium)
        let transaction = try XCTUnwrap(session.allTransactions().first { $0.productIdentifier == lifetime.id })
        try session.refundTransaction(identifier: transaction.identifier)
        await waitForAccess(false, store: reopened)
        XCTAssertFalse(reopened.isPremium)

        _ = try await session.buyProduct(identifier: AppConfig.premiumMonthlyProductID, options: [])
        await waitForAccess(true, store: reopened)
        XCTAssertTrue(reopened.isPremium)
        let subscription = try XCTUnwrap(session.allTransactions().last { $0.productIdentifier == AppConfig.premiumMonthlyProductID })
        try session.disableAutoRenewForTransaction(identifier: subscription.identifier)
        try session.expireSubscription(productIdentifier: AppConfig.premiumMonthlyProductID)
        await waitForAccess(false, store: reopened)
        XCTAssertFalse(reopened.isPremium)
        print("LocalStore: pending")
        session.askToBuyEnabled = true
        let yearly = try XCTUnwrap(store.product(for: AppConfig.premiumYearlyProductID))
        let pending = await reopened.purchase(yearly)
        XCTAssertEqual(pending, .pending)
        XCTAssertFalse(reopened.isPremium)
        var events: [AppEvent] = []
        let cancelled = PremiumStore(client: FoundationTests.FakePurchases(), analytics: AnalyticsClient(track: { events.append($0) }, setNickname: { _ in }))
        let cancellation = await cancelled.purchase(yearly)
        XCTAssertEqual(cancellation, .cancelled)
        XCTAssertNil(cancelled.message)
        XCTAssertEqual(events, [.purchaseStarted, .purchaseCancelled])
    }
}
