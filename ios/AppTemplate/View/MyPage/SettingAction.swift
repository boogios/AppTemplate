//
//  SettingAction.swift
//  AppTemplate
//

import Foundation

enum SettingAction {
    case none
    case openURL(URL)
    case navigate(SettingDestination)
    case privacyOptions
    case replayOnboarding
    case requestReview
}
