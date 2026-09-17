//
//  ThemeSettingView.swift
//  AppTemplate
//

import SwiftUI

struct ThemeSettingView: View {
    
    @EnvironmentObject var settingsStore: SettingsStore
    
    var body: some View {
        List {
            ForEach(AppTheme.allCases) { theme in
                Button {
                    settingsStore.setTheme(theme)
                } label: {
                    HStack {
                        Text(theme.displayName)
                            .foregroundStyle(Color.boogiosGray9)
                        
                        Spacer()
                        
                        if settingsStore.selectedTheme == theme {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.boogiosMain)
                        }
                    }
                }
                .listRowBackground(Color.boogiosWhite)
                .listRowSeparatorTint(Color.boogiosGray2)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.boogiosGray1)
        .customNavigationBar(title: MyPageL10n.themeTitle)
        .preferredColorScheme(settingsStore.selectedTheme.colorScheme)
    }
}
