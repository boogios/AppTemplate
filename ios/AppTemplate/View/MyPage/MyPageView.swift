//
//  MyPageView.swift
//  AppTemplate
//

import SwiftUI

struct MyPageView: View {
    
    @Environment(\.openURL) private var openURL
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var onboardingStore: OnboardingStore
    @EnvironmentObject var premiumStore: PremiumStore
    @ObservedObject private var adMobManager = AdMobManager.shared
    @State private var destination: SettingDestination?
    @State private var sheetDestination: SettingDestination?
    @State private var isToastPresented = false
    
    private let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    
    private var sections: [SettingSection] {
        SettingMenu.make(
            version: currentVersion,
            language: settingsStore.selectedLanguage,
            theme: settingsStore.selectedTheme,
            isPrivacyOptionsRequired: adMobManager.isPrivacyOptionsRequired
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                premiumCard
                VStack(spacing: 10) {
                    ForEach(sections) { section in
                        SettingSectionCard(section: section) { item in
                            handle(item.action)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
        .background(Color.boogiosGray1)
        .customNavigationBar(title: MyPageL10n.settingsTitle)
        .navigationDestination(item: $destination) { destination in
            switch destination {
            case .languageSettingView:
                LanguageSettingView()
            case .themeSettingView:
                ThemeSettingView()
            case .premiumPaywallView:
                EmptyView()
            }
        }
        .sheet(item: $sheetDestination) { destination in
            if destination == .premiumPaywallView {
                PremiumPaywallView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
        .boogiosToast(isPresented: $isToastPresented, message: settingsStore.toastMessage ?? "", bottomPadding: 50)
        .onChange(of: settingsStore.toastMessage) { _, newValue in
            isToastPresented = newValue != nil
        }
        .preferredColorScheme(settingsStore.selectedTheme.colorScheme)
    }
    
    private func handle(_ action: SettingAction) {
        switch action {
        case .none:
            break
        case .openURL(let url):
            openURL(url)
        case .navigate(let destination):
            if destination == .premiumPaywallView {
                sheetDestination = destination
            } else {
                self.destination = destination
            }
        case .privacyOptions:
            Task { await adMobManager.presentPrivacyOptions() }
        case .replayOnboarding:
            onboardingStore.presentReplay()
        case .requestReview:
            AppReviewRequester.shared.requestReview()
        }
    }

    private var premiumCard: some View {
        Button {
            sheetDestination = .premiumPaywallView
        } label: {
            HStack(spacing: 14) {
                Image(systemName: premiumStore.isPremium ? "checkmark.seal.fill" : "sparkles")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(PremiumL10n.cardTitle)
                        .font(.headline3)
                        .foregroundStyle(.white)
                    Text(premiumStore.isPremium ? PremiumL10n.cardActiveDescription : PremiumL10n.cardDescription)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.82))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 6)
                Image(systemName: premiumStore.isPremium ? "checkmark" : "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.88))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [Color.boogiosMain, Color.boogiosMain.opacity(0.72)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("settings.premium")
        .accessibilityLabel(PremiumL10n.cardTitle)
    }
}

#Preview {
    NavigationStack {
        MyPageView()
            .environmentObject(SettingsStore())
            .environmentObject(OnboardingStore())
            .environmentObject(PremiumStore())
    }
}
