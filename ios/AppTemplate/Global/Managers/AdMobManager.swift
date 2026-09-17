//
//  AdMobManager.swift
//  AppTemplate
//

import Combine
import Foundation
import GoogleMobileAds
import UserMessagingPlatform

@MainActor
final class AdMobManager: ObservableObject {
    
    static let shared = AdMobManager()

    @Published private(set) var canRequestAds = false
    @Published private(set) var isPrivacyOptionsRequired = false
    @Published private(set) var consentErrorMessage: String?
    
    private var didStart = false
    private var didRequestConsent = false
    
    private init() {}
    
    func startIfConfigured() {
        guard AppConfig.hasAdMobConfiguration else { return }
        guard didRequestConsent == false else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            await self.requestConsentForOnboarding()
            await TrackingAuthorizationManager.shared.requestIfNeeded()
        }
    }

    func requestConsentForOnboarding() async {
        guard AppConfig.hasAdMobConfiguration else { return }
        guard didRequestConsent == false else { return }
        didRequestConsent = true

        #if DEBUG
        if AppConfig.adMobTestDevice.isEmpty == false {
            MobileAds.shared.requestConfiguration.testDeviceIdentifiers = [
                AppConfig.adMobTestDevice
            ]
        }
        #endif

        MobileAds.shared.requestConfiguration.setPublisherFirstPartyIDEnabled(false)
        MobileAds.shared.requestConfiguration.publisherPrivacyPersonalizationState = .disabled

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let parameters = RequestParameters()
            ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { [weak self] requestError in
                Task { @MainActor [weak self] in
                    guard let self else {
                        continuation.resume()
                        return
                    }

                    self.consentErrorMessage = requestError?.localizedDescription
                    self.refreshConsentState()

                    do {
                        try await ConsentForm.loadAndPresentIfRequired(from: nil)
                        self.consentErrorMessage = nil
                    } catch {
                        self.consentErrorMessage = error.localizedDescription
                    }

                    self.refreshConsentState()
                    self.startMobileAdsIfAllowed()
                    continuation.resume()
                }
            }
        }
    }

    func presentPrivacyOptions() async {
        do {
            try await ConsentForm.presentPrivacyOptionsForm(from: nil)
            consentErrorMessage = nil
        } catch {
            consentErrorMessage = error.localizedDescription
        }

        refreshConsentState()
        startMobileAdsIfAllowed()
    }

    private func refreshConsentState() {
        canRequestAds = ConsentInformation.shared.canRequestAds
        isPrivacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
    }

    private func startMobileAdsIfAllowed() {
        guard canRequestAds else { return }
        guard didStart == false else { return }

        didStart = true
        MobileAds.shared.start()
    }
}
