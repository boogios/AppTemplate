//
//  LaunchView.swift
//  AppTemplate
//

import SwiftUI

struct LaunchView: View {

    @EnvironmentObject var onboardingStore: OnboardingStore
    
    var body: some View {
        if onboardingStore.hasCompletedOnboarding {
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
                onReplayDismiss: {}
            )
        }
    }
}

#Preview {
    LaunchView()
        .environmentObject(AppStore())
        .environmentObject(SettingsStore())
        .environmentObject(OnboardingStore())
        .environmentObject(NavigationPathManager())
}
