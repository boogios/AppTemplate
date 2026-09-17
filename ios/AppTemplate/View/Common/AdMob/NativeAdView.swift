//
//  NativeAdView.swift
//  AppTemplate
//

import GoogleMobileAds
import SwiftUI
import UIKit

struct NativeAdCardView: UIViewRepresentable {
    
    let nativeAd: NativeAd
    
    func makeUIView(context: Context) -> NativeAdContainerView {
        NativeAdContainerView()
    }
    
    func updateUIView(_ uiView: NativeAdContainerView, context: Context) {
        uiView.apply(nativeAd: nativeAd)
    }
    
    static func dismantleUIView(_ uiView: NativeAdContainerView, coordinator: ()) {
        uiView.prepareForReuse()
    }
}

final class NativeAdContainerView: NativeAdView {
    
    private let adBadgeLabel = UILabel()
    private let headlineLabel = UILabel()
    private let bodyLabel = UILabel()
    private let advertiserLabel = UILabel()
    private let iconImageView = UIImageView()
    private let mediaContentView = MediaView()
    private let callToActionLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViewHierarchy()
        configureAssetViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureViewHierarchy()
        configureAssetViews()
    }
    
    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 280)
    }
    
    func prepareForReuse() {
        nativeAd = nil
        headlineLabel.text = nil
        bodyLabel.text = nil
        advertiserLabel.text = nil
        iconImageView.image = nil
        callToActionLabel.text = nil
        mediaContentView.mediaContent = nil
    }
    
    func apply(nativeAd: NativeAd) {
        self.nativeAd = nil
        
        headlineLabel.text = nativeAd.headline
        
        bodyLabel.text = nativeAd.body
        bodyLabel.isHidden = nativeAd.body == nil
        
        advertiserLabel.text = nativeAd.advertiser
        advertiserLabel.isHidden = nativeAd.advertiser == nil
        
        if let icon = nativeAd.icon?.image {
            iconImageView.image = icon
            iconImageView.isHidden = false
        } else {
            iconImageView.image = nil
            iconImageView.isHidden = true
        }
        
        callToActionLabel.text = nativeAd.callToAction ?? CommonL10n.adCallToActionFallback
        callToActionLabel.isHidden = nativeAd.callToAction == nil
        
        mediaContentView.mediaContent = nativeAd.mediaContent
        mediaContentView.isHidden = false
        
        callToActionLabel.isUserInteractionEnabled = false
        callToActionView?.isUserInteractionEnabled = false
        
        self.nativeAd = nativeAd
    }
    
    private func configureViewHierarchy() {
        backgroundColor = UIColor(Color.boogiosWhite)
        layer.cornerRadius = 16
        layer.cornerCurve = .continuous
        clipsToBounds = true
        
        mediaContentView.translatesAutoresizingMaskIntoConstraints = false
        mediaContentView.contentMode = .scaleAspectFill
        mediaContentView.clipsToBounds = true
        mediaContentView.layer.cornerRadius = 12
        mediaContentView.layer.cornerCurve = .continuous
        mediaContentView.backgroundColor = UIColor(Color.boogiosGray2)
        
        adBadgeLabel.translatesAutoresizingMaskIntoConstraints = false
        adBadgeLabel.text = CommonL10n.adBadge
        adBadgeLabel.font = .systemFont(ofSize: 10, weight: .bold)
        adBadgeLabel.textColor = .white
        adBadgeLabel.backgroundColor = UIColor(Color.boogiosMain)
        adBadgeLabel.textAlignment = .center
        adBadgeLabel.layer.cornerRadius = 5
        adBadgeLabel.clipsToBounds = true
        
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.clipsToBounds = true
        iconImageView.layer.cornerRadius = 10
        iconImageView.layer.cornerCurve = .continuous
        iconImageView.backgroundColor = UIColor(Color.boogiosGray2)
        
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        headlineLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        headlineLabel.textColor = UIColor(Color.boogiosGray10)
        headlineLabel.numberOfLines = 2
        
        advertiserLabel.translatesAutoresizingMaskIntoConstraints = false
        advertiserLabel.font = .systemFont(ofSize: 11, weight: .regular)
        advertiserLabel.textColor = UIColor(Color.boogiosGray5)
        advertiserLabel.numberOfLines = 1
        
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyLabel.font = .systemFont(ofSize: 12, weight: .regular)
        bodyLabel.textColor = UIColor(Color.boogiosGray6)
        bodyLabel.numberOfLines = 2
        
        callToActionLabel.translatesAutoresizingMaskIntoConstraints = false
        callToActionLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        callToActionLabel.textColor = .white
        callToActionLabel.backgroundColor = UIColor(Color.boogiosMain)
        callToActionLabel.textAlignment = .center
        callToActionLabel.layer.cornerRadius = 14
        callToActionLabel.layer.cornerCurve = .continuous
        callToActionLabel.clipsToBounds = true
        callToActionLabel.numberOfLines = 1
        callToActionLabel.isUserInteractionEnabled = false
        
        addSubview(mediaContentView)
        addSubview(adBadgeLabel)
        addSubview(iconImageView)
        addSubview(headlineLabel)
        addSubview(advertiserLabel)
        addSubview(bodyLabel)
        addSubview(callToActionLabel)
        
        NSLayoutConstraint.activate([
            mediaContentView.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            mediaContentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            mediaContentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            mediaContentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120),
            
            adBadgeLabel.topAnchor.constraint(equalTo: mediaContentView.bottomAnchor, constant: 10),
            adBadgeLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            adBadgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 34),
            adBadgeLabel.heightAnchor.constraint(equalToConstant: 18),
            
            iconImageView.topAnchor.constraint(equalTo: adBadgeLabel.bottomAnchor, constant: 8),
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            iconImageView.widthAnchor.constraint(equalToConstant: 44),
            iconImageView.heightAnchor.constraint(equalToConstant: 44),
            
            callToActionLabel.centerYAnchor.constraint(equalTo: iconImageView.centerYAnchor),
            callToActionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            callToActionLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 74),
            callToActionLabel.heightAnchor.constraint(equalToConstant: 30),
            
            headlineLabel.topAnchor.constraint(equalTo: iconImageView.topAnchor),
            headlineLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 10),
            headlineLabel.trailingAnchor.constraint(equalTo: callToActionLabel.leadingAnchor, constant: -10),
            
            advertiserLabel.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: 2),
            advertiserLabel.leadingAnchor.constraint(equalTo: headlineLabel.leadingAnchor),
            advertiserLabel.trailingAnchor.constraint(equalTo: headlineLabel.trailingAnchor),
            
            bodyLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 8),
            bodyLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            bodyLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            bodyLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -14)
        ])
        
        headlineLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        bodyLabel.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        callToActionLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    
    private func configureAssetViews() {
        headlineView = headlineLabel
        bodyView = bodyLabel
        advertiserView = advertiserLabel
        iconView = iconImageView
        mediaView = mediaContentView
        callToActionView = callToActionLabel
    }
}

