//
//  NativeAdLoader.swift
//  AppTemplate
//

import Combine
import GoogleMobileAds
import SwiftUI
import UIKit

@MainActor
final class NativeAdLoader: NSObject, ObservableObject {
    
    @Published private(set) var nativeAd: NativeAd?
    @Published private(set) var isLoading = false
    @Published private(set) var didFailToLoad = false
    @Published private(set) var lastErrorMessage: String?
    
    private var adLoader: AdLoader?
    private var isActive = false
    private var consentCancellable: AnyCancellable?
    
    func start() {
        guard !isActive else { return }
        
        isActive = true
        nativeAd = nil
        isLoading = false
        didFailToLoad = false
        lastErrorMessage = nil

        consentCancellable = AdMobManager.shared.$canRequestAds
            .removeDuplicates()
            .filter { $0 }
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.loadAdIfNeeded()
                }
            }
    }
    
    func stop() {
        isActive = false
        nativeAd = nil
        isLoading = false
        didFailToLoad = false
        lastErrorMessage = nil

        consentCancellable?.cancel()
        consentCancellable = nil
        
        adLoader?.delegate = nil
        adLoader = nil
    }
    
    func loadAdIfNeeded() {
        guard AppConfig.hasAdMobNativeConfiguration else { return }
        guard AdMobManager.shared.canRequestAds else { return }
        guard nativeAd == nil else { return }
        guard !isLoading else { return }
        
        loadAd()
    }
    
    func consumeCurrentAdAndPreloadNext() {
        nativeAd = nil
        loadAdIfNeeded()
    }
    
    private func loadAd() {
        if !isActive {
            start()
        }
        
        guard AppConfig.hasAdMobNativeConfiguration else { return }
        guard AdMobManager.shared.canRequestAds else { return }
        guard !isLoading else { return }
        
        guard let rootViewController else {
            didFailToLoad = true
            lastErrorMessage = "RootViewController is nil"
            return
        }
        
        nativeAd = nil
        isLoading = true
        didFailToLoad = false
        lastErrorMessage = nil
        
        let mediaOptions = NativeAdMediaAdLoaderOptions()
        mediaOptions.mediaAspectRatio = .landscape
        
        adLoader = AdLoader(
            adUnitID: AppConfig.adMobNativeRequestID,
            rootViewController: rootViewController,
            adTypes: [.native],
            options: [mediaOptions]
        )
        adLoader?.delegate = self
        adLoader?.load(Request())
    }
    
    private var rootViewController: UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else {
            return nil
        }
        
        guard let rootViewController = windowScene.windows
            .first(where: { $0.isKeyWindow })?
            .rootViewController else {
            return nil
        }
        
        return topViewController(from: rootViewController)
    }
    
    private func topViewController(from rootViewController: UIViewController) -> UIViewController {
        if let presentedViewController = rootViewController.presentedViewController {
            return topViewController(from: presentedViewController)
        }
        
        if let navigationController = rootViewController as? UINavigationController,
           let visibleViewController = navigationController.visibleViewController {
            return topViewController(from: visibleViewController)
        }
        
        if let tabBarController = rootViewController as? UITabBarController,
           let selectedViewController = tabBarController.selectedViewController {
            return topViewController(from: selectedViewController)
        }
        
        return rootViewController
    }
}

extension NativeAdLoader: AdLoaderDelegate, NativeAdLoaderDelegate {
    
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        guard isActive else { return }
        
        nativeAd.delegate = self
        
        self.nativeAd = nativeAd
        isLoading = false
        didFailToLoad = false
        lastErrorMessage = nil
    }
    
    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: any Error) {
        nativeAd = nil
        isLoading = false
        didFailToLoad = true
        lastErrorMessage = error.localizedDescription
    }
}

extension NativeAdLoader: NativeAdDelegate {
    
    func nativeAdDidRecordImpression(_ nativeAd: NativeAd) {}
    
    func nativeAdDidRecordClick(_ nativeAd: NativeAd) {}
}
