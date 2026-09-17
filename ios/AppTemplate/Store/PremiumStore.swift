//
//  PremiumStore.swift
//  AppTemplate
//

import Foundation
import StoreKit

enum PremiumConfiguration {
    static let productIDs = [
        AppConfig.premiumMonthlyProductID,
        AppConfig.premiumYearlyProductID,
        AppConfig.premiumLifetimeProductID
    ]
}

enum PremiumPurchaseOutcome: Equatable {
    case purchased
    case pending
    case cancelled
    case failed
}

@MainActor
final class PremiumStore: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var isPremium = false
    @Published private(set) var isLoading = false
    @Published private(set) var isPurchasing = false
    @Published var message: String?

    private var transactionUpdatesTask: Task<Void, Never>?

    init() {
        transactionUpdatesTask = observeTransactionUpdates()
    }

    deinit {
        transactionUpdatesTask?.cancel()
    }

    func loadProducts() async {
        guard !isLoading else { return }
        isLoading = true
        message = nil
        defer { isLoading = false }

        do {
            let fetched = try await Product.products(for: PremiumConfiguration.productIDs)
            products = PremiumConfiguration.productIDs.compactMap { id in fetched.first { $0.id == id } }
            if products.isEmpty { message = PremiumL10n.productsUnavailable }
        } catch {
            products = []
            message = PremiumL10n.productsUnavailable
        }
    }

    func product(for id: String) -> Product? { products.first { $0.id == id } }

    func purchase(_ product: Product) async -> PremiumPurchaseOutcome {
        guard !isPurchasing else { return .failed }
        isPurchasing = true
        message = nil
        defer { isPurchasing = false }

        do {
            switch try await product.purchase() {
            case .success(let verification):
                let transaction = try verifiedTransaction(from: verification)
                guard PremiumConfiguration.productIDs.contains(transaction.productID) else { return .failed }
                await transaction.finish()
                await refreshEntitlements()
                message = isPremium ? PremiumL10n.purchaseSucceeded : PremiumL10n.purchasePending
                return isPremium ? .purchased : .pending
            case .pending:
                message = PremiumL10n.purchasePending
                return .pending
            case .userCancelled:
                return .cancelled
            @unknown default:
                message = PremiumL10n.purchaseFailed
                return .failed
            }
        } catch {
            message = PremiumL10n.purchaseFailed
            return .failed
        }
    }

    func restorePurchases() async {
        guard !isLoading else { return }
        isLoading = true
        message = nil
        defer { isLoading = false }

        do {
            try await StoreKit.AppStore.sync()
            await refreshEntitlements()
            message = isPremium ? PremiumL10n.purchaseRestored : PremiumL10n.nothingToRestore
        } catch {
            message = PremiumL10n.restoreFailed
        }
    }

    func refreshEntitlements() async {
        var hasPremiumEntitlement = false
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? verifiedTransaction(from: result),
                  PremiumConfiguration.productIDs.contains(transaction.productID),
                  transaction.revocationDate == nil else { continue }
            if let expirationDate = transaction.expirationDate, expirationDate <= .now { continue }
            hasPremiumEntitlement = true
            break
        }
        isPremium = hasPremiumEntitlement
    }

    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task { [weak self] in
            for await result in Transaction.updates {
                guard let self,
                      let transaction = try? self.verifiedTransaction(from: result),
                      PremiumConfiguration.productIDs.contains(transaction.productID) else { continue }
                await transaction.finish()
                await self.refreshEntitlements()
            }
        }
    }

    private func verifiedTransaction(from result: VerificationResult<Transaction>) throws -> Transaction {
        switch result {
        case .verified(let transaction): return transaction
        case .unverified: throw PremiumStoreError.unverifiedTransaction
        }
    }
}

private enum PremiumStoreError: Error {
    case unverifiedTransaction
}
