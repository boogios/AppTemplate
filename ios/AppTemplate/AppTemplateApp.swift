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
    
    @StateObject private var appStore = AppStore()
    @StateObject private var coordinator = AppCoordinator()
    @ObservedObject private var settingsStore: SettingsStore
    private var onboardingStore: OnboardingStore { coordinator.onboarding }
    private var premiumStore: PremiumStore { coordinator.premium }
    @StateObject private var navigationPathManager = NavigationPathManager()
    @AppStorage(AppLanguage.storageKey) private var selectedLanguageRaw: String = AppLanguage.system.rawValue
    
    init() {
        let coordinator = AppCoordinator()
        #if DEBUG
        if AppRuntime.isIsolated && ProcessInfo.processInfo.arguments.contains("-ui-test-dark") { coordinator.settings.setTheme(.dark) }
        #endif
        _coordinator = StateObject(wrappedValue: coordinator)
        _settingsStore = ObservedObject(wrappedValue: coordinator.settings)
    }

    var body: some Scene {
        WindowGroup {
            LaunchView(permissions: coordinator.dependencies.permissions)
                .task { await coordinator.prepare() }
                .environment(\.advertisingClient, coordinator.dependencies.advertising)
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
            Task { await coordinator.prepare() }
            guard onboardingStore.hasCompletedOnboarding else { return }
            coordinator.dependencies.advertising.start()
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        if !AppRuntime.isIsolated { MixpanelManager.shared.initializeIfConfigured() }
        return true
    }
}
