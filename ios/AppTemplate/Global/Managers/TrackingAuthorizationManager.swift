//
//  TrackingAuthorizationManager.swift
//  AppTemplate
//

import AppTrackingTransparency
import Foundation

@MainActor
final class TrackingAuthorizationManager {
    
    static let shared = TrackingAuthorizationManager()
    
    private var didRequest = false
    
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
        guard !AppRuntime.isIsolated else { return }
        guard AppConfig.hasAdMobConfiguration else { return }
        guard didRequest == false else { return }
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }

        didRequest = true
        try? await Task.sleep(for: .seconds(1))
        _ = await ATTrackingManager.requestTrackingAuthorization()
    }
}
