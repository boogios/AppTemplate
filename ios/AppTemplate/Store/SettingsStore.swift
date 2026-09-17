//
//  SettingsStore.swift
//  AppTemplate
//

import Foundation
import SwiftUI

final class SettingsStore: ObservableObject {
    
    @AppStorage(AppLanguage.storageKey) var selectedLanguageRaw: String = AppLanguage.system.rawValue
    @AppStorage("appTheme") var selectedThemeRaw: String = AppTheme.system.rawValue
    @Published var toastMessage: String?
    
    var selectedLanguage: AppLanguage {
        AppLanguage(rawValue: selectedLanguageRaw) ?? .system
    }
    
    var selectedTheme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .system
    }
    
    func setLanguage(_ language: AppLanguage) {
        AppLanguage.set(language)
        selectedLanguageRaw = language.rawValue
        toastMessage = MyPageL10n.languageUpdatedToast
    }
    
    func setTheme(_ theme: AppTheme) {
        selectedThemeRaw = theme.rawValue
        toastMessage = MyPageL10n.themeUpdatedToast
    }
    
}
