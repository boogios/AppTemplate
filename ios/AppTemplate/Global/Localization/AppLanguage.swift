//
//  AppLanguage.swift
//  AppTemplate
//

import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    
    case system
    case korean = "ko"
    case japanese = "ja"
    case englishUS = "english"
    case englishGB = "en-GB"
    case englishCA = "en-CA"
    case englishAU = "en-AU"
    case german = "de-DE"
    case french = "fr-FR"
    case portugueseBR = "pt-BR"
    case vietnamese = "vi"
    
    static let storageKey = "appLanguage"
    static let displayCases: [AppLanguage] = [
        .system,
        .englishUS,
        .englishGB,
        .englishCA,
        .englishAU,
        .korean,
        .japanese,
        .german,
        .french,
        .portugueseBR,
        .vietnamese
    ]
    
    var id: String { rawValue }
    
    var locale: Locale {
        switch self {
        case .system:
            return Locale.current
        case .korean:
            return Locale(identifier: "ko")
        case .japanese:
            return Locale(identifier: "ja")
        case .englishUS:
            return Locale(identifier: "en-US")
        case .englishGB:
            return Locale(identifier: "en-GB")
        case .englishCA:
            return Locale(identifier: "en-CA")
        case .englishAU:
            return Locale(identifier: "en-AU")
        case .german:
            return Locale(identifier: "de-DE")
        case .french:
            return Locale(identifier: "fr-FR")
        case .portugueseBR:
            return Locale(identifier: "pt-BR")
        case .vietnamese:
            return Locale(identifier: "vi")
        }
    }
    
    var resolved: AppLanguage {
        switch self {
        case .system:
            return Self.systemPreferredLanguage()
        default:
            return self
        }
    }
    
    var displayName: String {
        switch self {
        case .system:
            return MyPageL10n.languageSystem
        case .korean:
            return "한국어"
        case .japanese:
            return "日本語"
        case .englishUS:
            return "English (US)"
        case .englishGB:
            return "English (UK)"
        case .englishCA:
            return "English (Canada)"
        case .englishAU:
            return "English (Australia)"
        case .german:
            return "Deutsch"
        case .french:
            return "Français"
        case .portugueseBR:
            return "Português (Brasil)"
        case .vietnamese:
            return "Tiếng Việt"
        }
    }
    
    static var current: AppLanguage {
        let rawValue = UserDefaults.standard.string(forKey: storageKey) ?? AppLanguage.system.rawValue
        return AppLanguage(rawValue: rawValue) ?? .system
    }
    
    static func set(_ language: AppLanguage) {
        UserDefaults.standard.set(language.rawValue, forKey: storageKey)
    }
    
    private static func systemPreferredLanguage() -> AppLanguage {
        let identifier = Locale.preferredLanguages.first ?? Locale.current.identifier
        
        if identifier.hasPrefix("ko") {
            return .korean
        }
        
        if identifier.hasPrefix("ja") {
            return .japanese
        }
        
        if identifier.hasPrefix("en-GB") {
            return .englishGB
        }
        
        if identifier.hasPrefix("en-CA") {
            return .englishCA
        }
        
        if identifier.hasPrefix("en-AU") {
            return .englishAU
        }
        
        if identifier.hasPrefix("de") {
            return .german
        }
        
        if identifier.hasPrefix("fr") {
            return .french
        }
        
        if identifier.hasPrefix("pt-BR") || identifier.hasPrefix("pt_BR") {
            return .portugueseBR
        }
        
        if identifier.hasPrefix("vi") {
            return .vietnamese
        }
        
        return .englishUS
    }
}
