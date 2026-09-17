//
//  NotificationAuthorizationManager.swift
//  AppTemplate
//

import Foundation
import UserNotifications

@MainActor
final class NotificationAuthorizationManager {

    static let shared = NotificationAuthorizationManager()

    private init() {}

    func requestIfNeeded() async {
        if ProcessInfo.processInfo.arguments.contains("-ui-test-skip-permissions") {
            return
        }
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }

        _ = try? await center.requestAuthorization(options: [.alert, .badge, .sound])
    }
}
