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

    private var requestTask: Task<Void, Never>?
    func requestIfNeeded() async {
        guard !AppRuntime.isIsolated else { return }
        if let requestTask { await requestTask.value; return }
        let task = Task { await self.performRequest() }
        requestTask = task
        await task.value
        requestTask = nil
    }
    private func performRequest() async {
        if ProcessInfo.processInfo.arguments.contains("-ui-test-skip-permissions") {
            return
        }
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }

        _ = try? await center.requestAuthorization(options: [.alert, .badge, .sound])
    }
}
