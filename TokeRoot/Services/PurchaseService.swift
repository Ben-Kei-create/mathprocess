import Foundation
import StoreKit

@MainActor
@Observable
final class PurchaseService {
    static let shared = PurchaseService()
    static let removeAdsProductId = "app.tokeroot.removeads"

    private(set) var removeAdsProduct: Product?
    private(set) var hasRemoveAdsEntitlement = false
    private(set) var isLoading = false
    private(set) var isPurchasing = false
    var errorMessage: String?
    var statusMessage: String?

    private init() {}

    func loadProducts() async {
        guard removeAdsProduct == nil, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let products = try await Product.products(for: [Self.removeAdsProductId])
            removeAdsProduct = products.first
        } catch {
            errorMessage = "購入情報を読み込めませんでした。時間をおいてもう一度お試しください。"
        }
    }

    func purchaseRemoveAds() async -> Bool {
        errorMessage = nil
        statusMessage = nil

        if removeAdsProduct == nil {
            await loadProducts()
        }
        guard let product = removeAdsProduct else {
            errorMessage = "購入項目が見つかりませんでした。StoreKit 設定を確認してください。"
            return false
        }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try verified(verification)
                guard transaction.productID == Self.removeAdsProductId else { return false }
                await transaction.finish()
                hasRemoveAdsEntitlement = true
                return true
            case .pending:
                statusMessage = "購入の承認待ちです。完了すると広告が非表示になります。"
                return false
            case .userCancelled:
                return false
            @unknown default:
                errorMessage = "購入状態を確認できませんでした。もう一度お試しください。"
                return false
            }
        } catch {
            errorMessage = "購入を完了できませんでした。通信状態や Apple ID を確認してください。"
            return false
        }
    }

    func restorePurchases() async -> Bool {
        errorMessage = nil
        statusMessage = nil

        do {
            try await AppStore.sync()
            let restored = await refreshEntitlements()
            if !restored {
                statusMessage = "復元できる購入が見つかりませんでした。"
            }
            return restored
        } catch {
            errorMessage = "購入の復元に失敗しました。時間をおいてもう一度お試しください。"
            return false
        }
    }

    func refreshEntitlements() async -> Bool {
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? verified(result),
                  transaction.productID == Self.removeAdsProductId else {
                continue
            }
            hasRemoveAdsEntitlement = true
            return true
        }
        hasRemoveAdsEntitlement = false
        return false
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            return value
        case .unverified:
            throw PurchaseError.failedVerification
        }
    }
}

private enum PurchaseError: Error {
    case failedVerification
}
