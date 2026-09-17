//
//  SettingDestination.swift
//  AppTemplate
//

import Foundation

enum SettingDestination: Hashable {
    case languageSettingView
    case themeSettingView
    case premiumPaywallView
}

extension SettingDestination: Identifiable {
    var id: Self { self }
}
