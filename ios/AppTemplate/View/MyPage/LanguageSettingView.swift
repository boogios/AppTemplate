//
//  LanguageSettingView.swift
//  AppTemplate
//

import SwiftUI

struct LanguageSettingView: View {
    
    @EnvironmentObject var settingsStore: SettingsStore
    
    var body: some View {
        List {
            ForEach(AppLanguage.displayCases) { language in
                Button {
                    settingsStore.setLanguage(language)
                } label: {
                    HStack {
                        Text(language.displayName)
                            .foregroundStyle(Color.boogiosGray9)
                        
                        Spacer()
                        
                        if settingsStore.selectedLanguage == language {
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
        .customNavigationBar(title: MyPageL10n.languageTitle)
    }
}
