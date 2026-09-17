//
//  SettingMenu.swift
//  AppTemplate
//

import Foundation

enum SettingMenu {
    
    static func make(
        version: String,
        language: AppLanguage,
        theme: AppTheme,
        isPrivacyOptionsRequired: Bool
    ) -> [SettingSection] {
        var preferenceItems = [
            SettingItem(
                title: MyPageL10n.menuLanguage,
                trailingText: language.displayName,
                accessibilityIdentifier: "settings.language",
                action: .navigate(.languageSettingView)
            ),
            SettingItem(
                title: MyPageL10n.menuTheme,
                trailingText: theme.displayName,
                accessibilityIdentifier: "settings.theme",
                action: .navigate(.themeSettingView)
            )
        ]

        if isPrivacyOptionsRequired {
            preferenceItems.append(
                SettingItem(
                    title: MyPageL10n.menuPrivacyChoices,
                    accessibilityIdentifier: "settings.privacy-options",
                    action: .privacyOptions
                )
            )
        }
        
        return [
            SettingSection(items: preferenceItems),
            SettingSection(
                items: [
                    SettingItem(
                        title: MyPageL10n.menuReplayOnboarding,
                        accessibilityIdentifier: "settings.replay-onboarding",
                        action: .replayOnboarding
                    ),
                    SettingItem(
                        title: MyPageL10n.menuDeveloperApps,
                        accessibilityIdentifier: "settings.developer-apps",
                        action: .openURL(AppConfig.developerAppsURL)
                    ),
                    SettingItem(
                        title: MyPageL10n.menuReview,
                        accessibilityIdentifier: "settings.review",
                        action: .requestReview
                    ),
                    SettingItem(
                        title: MyPageL10n.menuSupport,
                        accessibilityIdentifier: "settings.support",
                        action: .openURL(AppConfig.supportURL)
                    ),
                    SettingItem(
                        title: MyPageL10n.menuTerms,
                        accessibilityIdentifier: "settings.terms",
                        action: .openURL(AppConfig.termsURL)
                    ),
                    SettingItem(
                        title: MyPageL10n.menuPrivacy,
                        accessibilityIdentifier: "settings.privacy",
                        action: .openURL(AppConfig.privacyURL)
                    )
                ]
            ),
            SettingSection(
                items: [
                    SettingItem(
                        title: MyPageL10n.menuVersion,
                        trailingText: "V.\(version)",
                        showsChevron: false,
                        accessibilityIdentifier: "settings.version",
                        action: .none
                    )
                ]
            )
        ]
    }
}
