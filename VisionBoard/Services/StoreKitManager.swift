import StoreKit
import SwiftUI

typealias StoreTransaction = StoreKit.Transaction

@Observable
final class StoreKitManager {
    static let shared = StoreKitManager()

    private(set) var products: [Product] = []
    private(set) var purchasedProductIDs: Set<String> = []
    private(set) var isLoading = false

    var isPro: Bool {
        !purchasedProductIDs.isEmpty
    }

    // Product IDs
    static let monthlyID = "com.wayneuconn.visionboard.monthly"
    static let yearlyID = "com.wayneuconn.visionboard.yearly"
    static let lifetimeID = "com.wayneuconn.visionboard.lifetime"

    private var updateListenerTask: Task<Void, Error>?

    init() {
        updateListenerTask = listenForTransactions()
        Task { await loadProducts() }
        Task { await updatePurchasedProducts() }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    func loadProducts() async {
        isLoading = true
        do {
            products = try await Product.products(for: [
                Self.monthlyID,
                Self.yearlyID,
                Self.lifetimeID
            ])
            products.sort { $0.price < $1.price }
        } catch {
            print("Failed to load products: \(error)")
        }
        isLoading = false
    }

    func purchase(_ product: Product) async throws -> StoreTransaction? {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchasedProducts()
            await transaction.finish()
            return transaction
        case .userCancelled:
            return nil
        case .pending:
            return nil
        @unknown default:
            return nil
        }
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await updatePurchasedProducts()
    }

    private func updatePurchasedProducts() async {
        var purchased: Set<String> = []
        for await result in StoreTransaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                purchased.insert(transaction.productID)
            }
        }
        purchasedProductIDs = purchased
    }

    private func checkVerified<T>(_ result: StoreKit.VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in StoreTransaction.updates {
                if let transaction = try? self.checkVerified(result) {
                    await self.updatePurchasedProducts()
                    await transaction.finish()
                }
            }
        }
    }

    enum StoreError: Error {
        case failedVerification
    }
}

// MARK: - Product Helpers

extension Product {
    var periodLabel: String {
        guard let subscription = self.subscription else { return "终身" }
        switch subscription.subscriptionPeriod.unit {
        case .month: return "月"
        case .year: return "年"
        default: return ""
        }
    }

    var monthlyEquivalent: String? {
        guard let subscription = self.subscription else { return nil }
        if subscription.subscriptionPeriod.unit == .year {
            let monthly = self.price / 12
            return "¥\(monthly.formatted(.number.precision(.fractionLength(1))))/月"
        }
        return nil
    }
}
