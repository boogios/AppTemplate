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
    
    func requestIfNeeded() async {
        guard AppConfig.hasAdMobConfiguration else { return }
        guard didRequest == false else { return }
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }

        didRequest = true
        try? await Task.sleep(for: .seconds(1))
        _ = await ATTrackingManager.requestTrackingAuthorization()
    }
}
