import Foundation
import StoreKit

enum PremiumConfiguration {
    static let productIDs = [AppConfig.premiumMonthlyProductID, AppConfig.premiumYearlyProductID, AppConfig.premiumLifetimeProductID]
}
enum PremiumPurchaseOutcome: Equatable { case purchased, pending, cancelled, failed }

@MainActor
final class PremiumStore: ObservableObject {
    @Published private(set) var productState: LoadState = .empty
    @Published private(set) var products: [Product] = []
    @Published private(set) var isPremium = false
    @Published private(set) var entitlementState: EntitlementState = .unknown
    @Published private(set) var lastCheckedAt: Date?
    @Published private(set) var isLoading = false
    @Published private(set) var isPurchasing = false
    @Published var message: String?
    private let client: any PurchaseClient
    private let analytics: AnalyticsClient
    private let now: () -> Date
    private var confirmed: [PremiumEntitlement] = []
    private var refreshAgain = false
    private var refreshTask: Task<Void, Never>?
    private var transactionUpdatesTask: Task<Void, Never>?

    init(client: (any PurchaseClient)? = nil, analytics: AnalyticsClient? = nil, now: @escaping () -> Date = Date.init) {
        self.client = client ?? (AppRuntime.isIsolated ? PreviewPurchaseClient() : StoreKitPurchaseClient())
        self.analytics = analytics ?? .live
        self.now = now
        let stream = self.client.updates()
        transactionUpdatesTask = Task { [weak self] in
            for await _ in stream {
                guard !Task.isCancelled else { break }
                await self?.refreshEntitlements(forceFresh: true)
            }
        }
    }
    deinit { transactionUpdatesTask?.cancel(); refreshTask?.cancel() }

    func loadProducts() async {
        guard !isLoading else { return }
        isLoading = true; productState = .loading; message = nil
        defer { isLoading = false }
        do {
            let fetched = try await client.products(ids: PremiumConfiguration.productIDs)
            products = PremiumConfiguration.productIDs.compactMap { id in fetched.first { $0.id == id } }
            productState = products.isEmpty ? .empty : .ready
            if products.isEmpty { message = PremiumL10n.productsUnavailable }
        } catch { productState = .failed; message = PremiumL10n.productsUnavailable }
    }
    func openPaywall() async {
        analytics.track(.premiumViewed)
        await refreshEntitlements()
        await loadProducts()
    }
    func product(for id: String) -> Product? { products.first { $0.id == id } }
    func purchase(_ product: Product) async -> PremiumPurchaseOutcome {
        guard !isPurchasing, !isLoading, PremiumConfiguration.productIDs.contains(product.id) else { return .failed }
        isPurchasing = true; message = nil
        defer { isPurchasing = false }
        analytics.track(.purchaseStarted)
        let outcome: PremiumPurchaseOutcome
        do { outcome = try await client.purchase(product) } catch { return purchaseFailed() }
        switch outcome {
        case .purchased:
            await refreshEntitlements(forceFresh: true)
            guard isPremium, entitlementState != .failed else { return purchaseFailed() }
            analytics.track(.purchaseCompleted); message = PremiumL10n.purchaseSucceeded
        case .pending: analytics.track(.purchasePending); message = PremiumL10n.purchasePending
        case .cancelled: analytics.track(.purchaseCancelled)
        case .failed: return purchaseFailed()
        }
        return outcome
    }
    private func purchaseFailed() -> PremiumPurchaseOutcome {
        analytics.track(.purchaseFailed); message = PremiumL10n.purchaseFailed; return .failed
    }
    func restorePurchases() async {
        guard !isLoading, !isPurchasing else { return }
        isLoading = true; message = nil
        defer { isLoading = false }
        do {
            try await client.restore()
            await refreshEntitlements(forceFresh: true)
            guard entitlementState != .failed else { message = PremiumL10n.restoreFailed; return }
            analytics.track(.purchaseRestored)
            message = isPremium ? PremiumL10n.purchaseRestored : PremiumL10n.nothingToRestore
        } catch { message = PremiumL10n.restoreFailed }
    }
    func refreshEntitlements(forceFresh: Bool = false) async {
        if forceFresh { refreshAgain = true }
        if let refreshTask { await refreshTask.value; return }
        let task = Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.refreshTask = nil }
            repeat {
            self.refreshAgain = false
            self.entitlementState = .checking
            do {
                self.confirmed = try await self.client.entitlements().filter { PremiumConfiguration.productIDs.contains($0.productID) }
                self.lastCheckedAt = self.now()
                self.isPremium = self.confirmed.contains { $0.isActive(at: self.now()) }
                self.entitlementState = self.isPremium ? .premium : .free
            } catch {
                self.isPremium = self.confirmed.contains { $0.isActive(at: self.now()) }
                self.entitlementState = .failed
            }
            } while self.refreshAgain
        }
        refreshTask = task
        await task.value
    }
}
