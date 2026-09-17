//
//  AppReviewRequester.swift
//  AppTemplate
//

import StoreKit
import UIKit

@MainActor
final class AppReviewRequester {
    static let shared = AppReviewRequester()

    private init() {}

    func requestReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else {
            return
        }

        // Apple decides whether and when the system review sheet is shown.
        StoreKit.AppStore.requestReview(in: scene)
    }
}
