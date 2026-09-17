//
//  AppTemplateApp.swift
//  AppTemplate
//

import SwiftUI
import UIKit

@main
struct AppTemplateApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    
    @ObservedObject var appStore = AppStore()
    @ObservedObject var settingsStore = SettingsStore()
    @ObservedObject var onboardingStore = OnboardingStore()
    @StateObject var premiumStore = PremiumStore()
    @ObservedObject var navigationPathManager = NavigationPathManager()
    @AppStorage(AppLanguage.storageKey) private var selectedLanguageRaw: String = AppLanguage.system.rawValue
    
    var body: some Scene {
        WindowGroup {
            LaunchView()
                .environment(\.locale, (AppLanguage(rawValue: selectedLanguageRaw) ?? .system).locale)
                .environmentObject(appStore)
                .environmentObject(settingsStore)
                .environmentObject(onboardingStore)
                .environmentObject(premiumStore)
                .environmentObject(navigationPathManager)
                .preferredColorScheme(settingsStore.selectedTheme.colorScheme)
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            guard onboardingStore.hasCompletedOnboarding else { return }
            AdMobManager.shared.startIfConfigured()
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        MixpanelManager.shared.initializeIfConfigured()
        return true
    }
}
