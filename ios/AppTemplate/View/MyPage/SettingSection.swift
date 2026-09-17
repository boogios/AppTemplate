//
//  SettingSection.swift
//  AppTemplate
//

import Foundation

struct SettingSection: Identifiable {
    let id = UUID()
    let items: [SettingItem]
}

struct SettingItem: Identifiable {
    enum Role: Hashable {
        case normal
        case destructive
    }
    
    let id = UUID()
    let title: String
    var trailingText: String? = nil
    var showsChevron: Bool = true
    var role: Role = .normal
    var accessibilityIdentifier: String? = nil
    let action: SettingAction
}
