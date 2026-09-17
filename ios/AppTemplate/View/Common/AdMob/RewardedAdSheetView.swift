//
//  RewardedAdSheetView.swift
//  AppTemplate
//

import GoogleMobileAds
import SwiftUI
import UIKit

struct RewardedAdSheetView: UIViewControllerRepresentable {
    
    @Binding var isPresented: Bool
    
    var adUnitID: String
    var onEarnReward: () -> Void
    var onFail: (() -> Void)?
    
    init(
        isPresented: Binding<Bool>,
        adUnitID: String = AppConfig.adMobRewardID,
        onEarnReward: @escaping () -> Void,
        onFail: (() -> Void)? = nil
    ) {
        self._isPresented = isPresented
        self.adUnitID = adUnitID
        self.onEarnReward = onEarnReward
        self.onFail = onFail
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        viewController.view.isHidden = true
        viewController.modalPresentationStyle = .overFullScreen
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard isPresented else { return }
        
        DispatchQueue.main.async {
            isPresented = false
        }
        
        guard AppConfig.hasAdMobRewardConfiguration else {
            onFail?()
            return
        }
        guard AdMobManager.shared.canRequestAds else {
            onFail?()
            return
        }
        
        RewardedAdService.shared.present(
            adUnitID: adUnitID,
            from: uiViewController,
            onEarnReward: onEarnReward,
            onFail: onFail
        )
    }
}

@MainActor
final class RewardedAdService: NSObject, FullScreenContentDelegate {
    
    static let shared = RewardedAdService()
    
    private var ad: RewardedAd?
    private var isLoading = false
    private var isPresenting = false
    private var pendingPresent: ((RewardedAd) -> Void)?
    private var onDismiss: (() -> Void)?
    
    private override init() {}
    
    func preload(adUnitID: String = AppConfig.adMobRewardID) {
        guard AppConfig.hasAdMobRewardConfiguration else { return }
        guard ad == nil else { return }
        
        load(adUnitID: adUnitID)
    }
    
    func present(
        adUnitID: String = AppConfig.adMobRewardID,
        from rootViewController: UIViewController,
        onEarnReward: @escaping () -> Void,
        onDismiss: (() -> Void)? = nil,
        onFail: (() -> Void)? = nil
    ) {
        guard AppConfig.hasAdMobRewardConfiguration else {
            onFail?()
            onDismiss?()
            return
        }
        
        guard !isPresenting else { return }
        
        let presentBlock: (RewardedAd) -> Void = { [weak self] ad in
            guard let self else { return }
            
            self.isPresenting = true
            self.ad = nil
            ad.fullScreenContentDelegate = self
            ad.present(from: rootViewController) {
                onEarnReward()
            }
            self.load(adUnitID: adUnitID)
        }
        
        self.onDismiss = { [weak self] in
            self?.isPresenting = false
            onDismiss?()
        }
        
        if let ad {
            presentBlock(ad)
        } else {
            pendingPresent = presentBlock
            load(adUnitID: adUnitID) { [weak self] didLoad in
                guard let self else { return }
                
                if !didLoad {
                    self.pendingPresent = nil
                    onFail?()
                    onDismiss?()
                }
            }
        }
    }
    
    private func load(adUnitID: String, completion: ((Bool) -> Void)? = nil) {
        guard AppConfig.hasAdMobRewardConfiguration else {
            completion?(false)
            return
        }
        guard AdMobManager.shared.canRequestAds else {
            completion?(false)
            return
        }
        
        guard !isLoading else { return }
        
        isLoading = true
        
        RewardedAd.load(with: adUnitID, request: Request()) { [weak self] ad, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                
                self.isLoading = false
                
                if error != nil {
                    self.ad = nil
                    completion?(false)
                    return
                }
                
                self.ad = ad
                
                if let ad, let presentBlock = self.pendingPresent {
                    self.pendingPresent = nil
                    presentBlock(ad)
                }
                
                completion?(true)
            }
        }
    }
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        onDismiss?()
        onDismiss = nil
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        onDismiss?()
        onDismiss = nil
    }
}
