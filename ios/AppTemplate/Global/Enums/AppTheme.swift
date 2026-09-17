//
//  AppTheme.swift
//  AppTemplate
//

import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    
    case system
    case light
    case dark
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system:
            return MyPageL10n.themeSystem
        case .light:
            return MyPageL10n.themeLight
        case .dark:
            return MyPageL10n.themeDark
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
