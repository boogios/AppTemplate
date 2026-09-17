//
//  MainView.swift
//  AppTemplate
//

import SwiftUI

struct MainView: View {
    
    @EnvironmentObject var appStore: AppStore
    @EnvironmentObject var navigationPathManager: NavigationPathManager
    
    var body: some View {
        TabView(selection: $appStore.selectedTab) {
            NavigationStack(path: $navigationPathManager.homePath) {
                HomeView()
            }
            .tabItem {
                Label(CommonL10n.tabHome, systemImage: "house.fill")
            }
            .tag(AppTab.home)
            
            NavigationStack(path: $navigationPathManager.myPagePath) {
                MyPageView()
            }
            .tabItem {
                Label(CommonL10n.tabSettings, systemImage: "gearshape.fill")
            }
            .tag(AppTab.myPage)
        }
        .tint(Color.boogiosMain)
    }
}

#Preview {
    MainView()
        .environmentObject(AppStore())
        .environmentObject(SettingsStore())
        .environmentObject(NavigationPathManager())
}
