//
//  PremiumPaywallView.swift
//  AppTemplate
//

import StoreKit
import SwiftUI

struct PremiumPaywallView: View {
    @EnvironmentObject private var premiumStore: PremiumStore
    @EnvironmentObject private var settingsStore: SettingsStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProductID: String?

    private var selectedProduct: Product? {
        guard let selectedProductID else { return nil }
        return premiumStore.product(for: selectedProductID)
    }

    private var orderedProducts: [Product] {
        let order = [AppConfig.premiumYearlyProductID, AppConfig.premiumMonthlyProductID, AppConfig.premiumLifetimeProductID]
        let byID = Dictionary(uniqueKeysWithValues: premiumStore.products.map { ($0.id, $0) })
        return order.compactMap { byID[$0] } + premiumStore.products.filter { !order.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    hero
                    if premiumStore.isPremium { activeState } else { benefits; products }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .background(Color.boogiosGray1)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if !premiumStore.isPremium { purchaseFooter }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .bold))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel(CommonL10n.close)
                    .accessibilityIdentifier("premium.close")
                }
            }
        }
        .task {
            await premiumStore.loadProducts()
            if selectedProductID == nil { selectedProductID = orderedProducts.first?.id }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.14), in: Circle())
                Spacer()
                Text(PremiumL10n.cardTitle)
                    .font(.caption1)
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.14), in: Capsule())
            }
            Text(PremiumL10n.paywallTitle)
                .font(.headline1)
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
            Text(PremiumL10n.paywallSubtitle)
                .font(.body2)
                .foregroundStyle(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [Color.boogiosMain, Color.boogiosMain.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .accessibilityIdentifier("premium.hero")
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(PremiumL10n.benefitsTitle).font(.subtitle2).foregroundStyle(Color.boogiosGray9)
            benefitRow("infinity", PremiumL10n.benefitUnlimited)
            benefitRow("nosign", PremiumL10n.benefitAdFree)
            benefitRow("sparkles", PremiumL10n.benefitUpdates)
        }
        .padding(16)
        .background(Color.boogiosWhite, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func benefitRow(_ symbol: String, _ title: String) -> some View {
        HStack(spacing: 11) {
            Image(systemName: symbol).foregroundStyle(Color.boogiosMain).frame(width: 22)
            Text(title).font(.body2).foregroundStyle(Color.boogiosGray9).frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "checkmark").font(.caption1).foregroundStyle(Color.boogiosGray7)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(Color.boogiosGray1, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @ViewBuilder private var products: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(PremiumL10n.plansTitle).font(.subtitle2).foregroundStyle(Color.boogiosGray9)
            if orderedProducts.isEmpty {
                Text(premiumStore.isLoading ? PremiumL10n.paywallSubtitle : (premiumStore.message ?? PremiumL10n.productsUnavailable))
                    .font(.body2).foregroundStyle(Color.boogiosGray7).fixedSize(horizontal: false, vertical: true)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.boogiosWhite, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                ForEach(orderedProducts, id: \.id) { planRow($0) }
            }
        }
    }

    private func planRow(_ product: Product) -> some View {
        let selected = selectedProductID == product.id
        let isYearly = product.id == AppConfig.premiumYearlyProductID
        return Button {
            selectedProductID = product.id
        } label: {
            HStack(spacing: 12) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(selected ? Color.boogiosMain : Color.boogiosGray6)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 7) {
                        Text(PremiumL10n.productTitle(product.id, fallback: product.displayName)).font(.body1).foregroundStyle(Color.boogiosGray9)
                        if isYearly { Text(PremiumL10n.recommended).font(.caption2).foregroundStyle(Color.boogiosMain).padding(.horizontal, 7).padding(.vertical, 3).background(Color.boogiosMainSoft, in: Capsule()) }
                    }
                    Text(product.id == AppConfig.premiumLifetimeProductID ? PremiumL10n.lifetimeDescription : PremiumL10n.renewsUntilCancelled)
                        .font(.caption2).foregroundStyle(Color.boogiosGray7)
                }
                Spacer(minLength: 8)
                Text(product.displayPrice).font(.body1).foregroundStyle(Color.boogiosGray9)
            }
            .padding(15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(selected ? Color.boogiosMainSoft.opacity(0.6) : Color.boogiosWhite, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(selected ? Color.boogiosMain : Color.boogiosGray3, lineWidth: selected ? 1.5 : 1) }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("premium.plan.\(product.id)")
    }

    private var activeState: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill").font(.system(size: 30)).foregroundStyle(Color.boogiosMain)
            Text(PremiumL10n.active).font(.headline2).foregroundStyle(Color.boogiosGray9)
            Text(PremiumL10n.activeDescription).font(.body2).foregroundStyle(Color.boogiosGray7).multilineTextAlignment(.center)
            BoogiosNavigationButton(title: CommonL10n.done, action: { dismiss() })
        }
        .frame(maxWidth: .infinity).padding(20).background(Color.boogiosWhite, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityIdentifier("premium.active")
    }

    private var purchaseFooter: some View {
        VStack(spacing: 9) {
            BoogiosNavigationButton(title: selectedProduct.map { "\(PremiumL10n.purchase) · \($0.displayPrice)" } ?? PremiumL10n.purchase, action: {
                guard let selectedProduct else { return }
                Task { if await premiumStore.purchase(selectedProduct) == .purchased { dismiss() } }
            })
            .opacity(selectedProduct == nil || premiumStore.isPurchasing || premiumStore.isLoading ? 0.55 : 1)
            .disabled(selectedProduct == nil || premiumStore.isPurchasing || premiumStore.isLoading)
            .accessibilityIdentifier("premium.purchase")

            Button { Task { await premiumStore.restorePurchases() } } label: {
                HStack(spacing: 6) { if premiumStore.isLoading { ProgressView().controlSize(.mini) }; Text(PremiumL10n.restore) }
            }
            .font(.caption1)
            .foregroundStyle(Color.boogiosGray7)
            .accessibilityIdentifier("premium.restore")

            if let message = premiumStore.message, premiumStore.products.isEmpty == false {
                Text(message).font(.caption2).foregroundStyle(Color.boogiosGray7).multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 8).background(Color.boogiosGray1)
    }
}

#Preview {
    PremiumPaywallView().environmentObject(PremiumStore()).environmentObject(SettingsStore())
}
