//
//  Config.swift
//  AppTemplate
//

import Foundation

enum AppConfig {
    
    enum Keys {
        enum Plist {
            static let adMobAppID = "GADApplicationIdentifier"
            static let adMobBannerID = "ADMOB_BANNER_ID"
            static let adMobNativeID = "ADMOB_NATIVE_ID"
            static let adMobRewardID = "ADMOB_REWARD_ID"
            static let adMobTestDevice = "ADMOB_TEST_DEVICE"
            static let mixpanelToken = "MIXPANEL_TOKEN"
            static let supabaseURL = "SUPABASE_URL"
            static let supabasePublishableKey = "SUPABASE_PUBLISHABLE_KEY"
            static let supabaseRedirectURL = "SUPABASE_REDIRECT_URL"
        }
    }
    
    static let appName = "AppTemplate"
    static let appStoreID = "0000000000"
    static let mainColorHex = "#475CEF"

    // Replace these identifiers with the products created in App Store Connect.
    // The generator replaces the com.boogios.template prefix with the new bundle ID.
    static let premiumMonthlyProductID = "com.boogios.template.premium.monthly"
    static let premiumYearlyProductID = "com.boogios.template.premium.yearly"
    static let premiumLifetimeProductID = "com.boogios.template.premium.lifetime"
    
    static let supportURL = URL(string: "https://www.instagram.com/dev._.boogios")!
    static let developerAppsURL = URL(string: "https://boogios-studio.vercel.app/")!
    static let termsURL = URL(string: "https://example.com/terms")!
    static let privacyURL = URL(string: "https://example.com/privacy")!
    
    static var adMobAppID: String {
        infoValue(for: Keys.Plist.adMobAppID)
    }
    
    static var adMobBannerID: String {
        infoValue(for: Keys.Plist.adMobBannerID)
    }
    
    static var adMobNativeID: String {
        infoValue(for: Keys.Plist.adMobNativeID)
    }
    
    static var adMobNativeRequestID: String {
        #if DEBUG
        return "ca-app-pub-3940256099942544/3986624511"
        #else
        return adMobNativeID
        #endif
    }
    
    static var adMobRewardID: String {
        infoValue(for: Keys.Plist.adMobRewardID)
    }
    
    static var adMobTestDevice: String {
        infoValue(for: Keys.Plist.adMobTestDevice)
    }
    
    static var mixpanelToken: String {
        infoValue(for: Keys.Plist.mixpanelToken)
    }
    
    static var supabaseURL: URL? {
        infoURLValue(for: Keys.Plist.supabaseURL)
    }
    
    static var supabaseURLString: String {
        normalizedURLString(infoValue(for: Keys.Plist.supabaseURL))
    }
    
    static var supabasePublishableKey: String {
        infoValue(for: Keys.Plist.supabasePublishableKey)
    }
    
    static var supabaseKey: String {
        supabasePublishableKey
    }
    
    static var supabaseRedirectURL: URL? {
        infoURLValue(for: Keys.Plist.supabaseRedirectURL)
    }
    
    static var hasAdMobConfiguration: Bool {
        !adMobAppID.isPlaceholderValue
    }
    
    static var hasAdMobBannerConfiguration: Bool {
        hasAdMobConfiguration && !adMobBannerID.isPlaceholderValue
    }
    
    static var hasAdMobNativeConfiguration: Bool {
        hasAdMobConfiguration && !adMobNativeRequestID.isPlaceholderValue
    }
    
    static var hasAdMobRewardConfiguration: Bool {
        hasAdMobConfiguration && !adMobRewardID.isPlaceholderValue
    }
    
    static var hasMixpanelConfiguration: Bool {
        !mixpanelToken.isPlaceholderValue
    }
    
    static var hasSupabaseConfiguration: Bool {
        supabaseURL != nil && !supabasePublishableKey.isPlaceholderValue
    }
    
    private static func infoValue(for key: String) -> String {
        Bundle.main.object(forInfoDictionaryKey: key) as? String ?? ""
    }
    
    private static func infoURLValue(for key: String) -> URL? {
        let value = normalizedURLString(infoValue(for: key))
        guard !value.isEmpty, value.isPlaceholderValue == false else { return nil }
        return URL(string: value)
    }
    
    private static func normalizedURLString(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "https:/$()/", with: "https://")
            .replacingOccurrences(of: "http:/$()/", with: "http://")
    }
}

private extension String {
    var isPlaceholderValue: Bool {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty
            || trimmed.hasPrefix("$(")
            || trimmed.hasPrefix("your_")
            || trimmed.hasPrefix("ca-app-pub-xxxxxxxxxxxxxxxx")
            || trimmed == "ca-app-pub-3940256099942544~1458002511"
            || trimmed == "https://your-project-ref.supabase.co"
            || trimmed == "https:/$()/your-project-ref.supabase.co"
            || trimmed == "your_supabase_publishable_key"
            || trimmed.contains("yyyyyyyyyy")
    }
}
