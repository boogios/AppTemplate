//
//  MixpanelManager.swift
//  AppTemplate
//

import Foundation
import Mixpanel

@MainActor
final class MixpanelManager {
    
    static let shared = MixpanelManager()
    
    private var didInitialize = false
    
    private init() {}
    
    func initializeIfConfigured() {
        guard AppConfig.hasMixpanelConfiguration else { return }
        guard didInitialize == false else { return }
        
        Mixpanel.initialize(token: AppConfig.mixpanelToken, trackAutomaticEvents: false)
        Mixpanel.mainInstance().loggingEnabled = false
        Mixpanel.mainInstance().registerSuperProperties([
            "platform": "iOS",
            "app_version": appVersion,
            "build_number": buildNumber
        ])
        
        didInitialize = true
    }
    
    func identify(userId: String) {
        guard didInitialize else { return }
        
        Mixpanel.mainInstance().identify(distinctId: userId)
        Mixpanel.mainInstance().people.set(
            properties: [
                "platform": "iOS",
                "user_id": userId
            ]
        )
    }
    
    func reset() {
        guard didInitialize else { return }
        
        Mixpanel.mainInstance().reset()
    }
    
    func setUserProperties(nickname: String) {
        guard didInitialize else { return }
        
        Mixpanel.mainInstance().people.set(properties: ["$name": nickname])
    }
    
    func setUserMembershipStatus(status: Bool) {
        guard didInitialize else { return }
        
        Mixpanel.mainInstance().people.set(
            properties: [
                "membership_status": "\(status)"
            ]
        )
    }
    
    func setUserProperties(key: String, value: String) {
        guard didInitialize else { return }
        
        Mixpanel.mainInstance().people.set(
            properties: [
                key: value
            ]
        )
    }
    
    func track(event: String, properties: [String: MixpanelType] = [:]) {
        guard didInitialize else { return }
        
        Mixpanel.mainInstance().track(event: event, properties: properties)
    }
    
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
    }
    
    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
    }
}
