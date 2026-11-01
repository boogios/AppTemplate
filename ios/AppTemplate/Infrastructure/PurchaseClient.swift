import Foundation
import StoreKit

struct PremiumEntitlement: Equatable {
    let productID: String
    let expiresAt: Date?
    let revoked: Bool
    func isActive(at date: Date) -> Bool { !revoked && (expiresAt.map { $0 > date } ?? true) }
}

@MainActor
protocol PurchaseClient {
    func products(ids: [String]) async throws -> [Product]
    func entitlements() async throws -> [PremiumEntitlement]
    func purchase(_ product: Product) async throws -> PremiumPurchaseOutcome
    func restore() async throws
    func updates() -> AsyncStream<Void>
}

@MainActor
final class StoreKitPurchaseClient: PurchaseClient {
    func products(ids: [String]) async throws -> [Product] { try await Product.products(for: ids) }
    func entitlements() async throws -> [PremiumEntitlement] {
        var values: [PremiumEntitlement] = []
        for await result in Transaction.currentEntitlements {
            let transaction: Transaction
            switch result {
            case .verified(let value): transaction = value
            case .unverified(let value, _):
                if PremiumConfiguration.productIDs.contains(value.productID) { throw PurchaseError.unverified }
                continue
            }
            values.append(.init(productID: transaction.productID, expiresAt: transaction.expirationDate,
                                revoked: transaction.revocationDate != nil))
        }
        return values
    }
    func purchase(_ product: Product) async throws -> PremiumPurchaseOutcome {
        switch try await product.purchase() {
        case .success(let result):
            guard case .verified(let transaction) = result,
                  PremiumConfiguration.productIDs.contains(transaction.productID) else { throw PurchaseError.unverified }
            await transaction.finish()
            return .purchased
        case .pending: return .pending
        case .userCancelled: return .cancelled
        @unknown default: return .failed
        }
    }
    func restore() async throws { try await StoreKit.AppStore.sync() }
    func updates() -> AsyncStream<Void> {
        AsyncStream { continuation in
            let task = Task {
                for await result in Transaction.updates {
                    guard !Task.isCancelled else { break }
                    if case .verified(let transaction) = result,
                       PremiumConfiguration.productIDs.contains(transaction.productID) {
                        await transaction.finish()
                        continuation.yield(())
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
    private enum PurchaseError: Error { case unverified }
}

@MainActor
final class PreviewPurchaseClient: PurchaseClient {
    func products(ids: [String]) async throws -> [Product] { [] }
    func entitlements() async throws -> [PremiumEntitlement] { [] }
    func purchase(_ product: Product) async throws -> PremiumPurchaseOutcome { .cancelled }
    func restore() async throws {}
    func updates() -> AsyncStream<Void> { AsyncStream { $0.finish() } }
}
