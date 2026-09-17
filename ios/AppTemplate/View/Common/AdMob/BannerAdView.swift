//
//  BannerAdView.swift
//  AppTemplate
//

import GoogleMobileAds
import SwiftUI
import UIKit

struct BannerAdView: UIViewControllerRepresentable {
    
    private let adUnitID: String
    
    init(adUnitID: String = AppConfig.adMobBannerID) {
        self.adUnitID = adUnitID
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .clear
        
        guard AppConfig.hasAdMobBannerConfiguration else {
            return viewController
        }
        guard AdMobManager.shared.canRequestAds else {
            return viewController
        }
        
        let width = UIScreen.main.bounds.width
        let adSize = largeAnchoredAdaptiveBanner(width: width)
        let bannerView = BannerView(adSize: adSize)
        
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = viewController
        bannerView.backgroundColor = .clear
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        
        viewController.view.addSubview(bannerView)
        
        NSLayoutConstraint.activate([
            bannerView.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            bannerView.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor),
            bannerView.widthAnchor.constraint(equalToConstant: adSize.size.width),
            bannerView.heightAnchor.constraint(equalToConstant: adSize.size.height)
        ])
        
        bannerView.load(Request())
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
