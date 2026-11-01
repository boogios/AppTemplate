//
//  LaunchView.swift
//  AppTemplate
//

import SwiftUI

struct LaunchView: View {

    @EnvironmentObject var onboardingStore: OnboardingStore
    @EnvironmentObject var settingsStore: SettingsStore
    var permissions: PermissionClient = .live
    
    var body: some View {
        if onboardingStore.loadState != .ready || settingsStore.loadState != .ready {
            AsyncStatusView(isLoading: onboardingStore.loadState == .loading || settingsStore.loadState == .loading,
                message: (onboardingStore.loadState == .failed || settingsStore.loadState == .failed) ? FoundationL10n.loadFailed : nil,
                retry: { onboardingStore.reload(); settingsStore.reload() })
        } else if onboardingStore.hasCompletedOnboarding {
            ZStack {
                MainView()

                if onboardingStore.isReplayPresented {
                    OnboardingView(
                        mode: .replay,
                        onComplete: { _ in },
                        onReplayDismiss: onboardingStore.dismissReplay
                    )
                }
            }
        } else {
            OnboardingView(
                mode: .initial,
                onComplete: onboardingStore.complete,
                onReplayDismiss: {},
                permissions: permissions,
                saveFailed: onboardingStore.saveFailed
            )
        }
    }
}

#Preview { AppPreview { LaunchView(permissions: .disabled) } }
