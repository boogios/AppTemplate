import GoogleMobileAds
import SwiftUI
import UIKit

@MainActor
final class RewardAttempt {
    private(set) var earned = false
    private var completion: ((RewardedAdOutcome) -> Void)?
    init(completion: @escaping (RewardedAdOutcome) -> Void) { self.completion = completion }
    func earn() { earned = true }
    func finish(failed: Bool = false) {
        let callback = completion
        completion = nil
        callback?(failed ? .failed : earned ? .rewarded : .dismissed)
    }
}

@MainActor
final class RewardGate {
    private(set) var current: RewardAttempt?
    func begin(_ request: RewardAttempt, available: Bool) -> Bool {
        guard available, current == nil else { request.finish(failed: true); return false }
        current = request; return true
    }
    func finish(_ request: RewardAttempt, failed: Bool = false) {
        guard current === request else { return }
        current = nil
        request.finish(failed: failed)
    }
}

struct RewardedAdSheetView: UIViewControllerRepresentable {
    @Environment(\.advertisingClient) private var advertisingClient
    @Binding var isPresented: Bool
    var adUnitID: String = AppConfig.adMobRewardID
    var onEarnReward: () -> Void
    var onFail: (() -> Void)? = nil
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.isHidden = true
        return controller
    }
    func updateUIViewController(_ controller: UIViewController, context: Context) {
        guard isPresented else { return }
        // Consume the trigger before starting async work, including repeated SwiftUI updates.
        guard !context.coordinator.requested else { return }
        context.coordinator.requested = true
        DispatchQueue.main.async {
            isPresented = false
            context.coordinator.requested = false
        }
        (advertisingClient ?? .live).reward(adUnitID, controller) { outcome in
            if outcome == .rewarded { onEarnReward() }
            else if outcome == .failed { onFail?() }
        }
    }
    final class Coordinator { var requested = false }
    func makeCoordinator() -> Coordinator { Coordinator() }
}

@MainActor
final class RewardedAdService: NSObject, FullScreenContentDelegate {
    static let shared = RewardedAdService()
    private var ad: RewardedAd?
    private var loadedID: String?
    private var loadingID: String?
    private var pending: ((RewardedAd?) -> Void)?
    private let requests = RewardGate()
    private var attempt: RewardAttempt? { requests.current }
    private var presenting = false
    private var presentedAd: RewardedAd?

    func preload(adUnitID: String = AppConfig.adMobRewardID) {
        guard available, ad == nil, loadingID == nil else { return }
        load(adUnitID)
    }
    private var available: Bool {
        !AppRuntime.isIsolated && AppConfig.hasAdMobRewardConfiguration && AdMobManager.shared.canRequestAds
    }
    func present(adUnitID: String = AppConfig.adMobRewardID, from controller: UIViewController,
                 onEarnReward: @escaping () -> Void, onDismiss: (() -> Void)? = nil, onFail: (() -> Void)? = nil) {
        present(adUnitID: adUnitID, from: controller) { outcome in
            switch outcome {
            case .rewarded: onEarnReward()
            case .dismissed: onDismiss?()
            case .failed: onFail?()
            }
        }
    }
    func present(adUnitID: String, from controller: UIViewController, completion: @escaping (RewardedAdOutcome) -> Void) {
        let analytics = AnalyticsClient.live
        analytics.track(.rewardedAdRequested)
        let request = RewardAttempt { outcome in
            analytics.track(outcome == .rewarded ? .rewardedAdCompleted : outcome == .dismissed ? .rewardedAdDismissed : .rewardedAdFailed)
            completion(outcome)
        }
        guard requests.begin(request, available: available && !presenting && (loadingID == nil || loadingID == adUnitID)) else { return }
        let show: (RewardedAd?) -> Void = { [weak self, weak controller] ad in
            guard let self, self.attempt === request else { return }
            guard let ad, let controller, controller.viewIfLoaded?.window != nil else { self.finish(failed: true); return }
            self.ad = nil; self.loadedID = nil; self.presenting = true
            self.presentedAd = ad
            ad.fullScreenContentDelegate = self
            ad.present(from: controller) { request.earn() }
        }
        if let ad, loadedID == adUnitID { show(ad) }
        else {
            self.ad = nil; loadedID = nil; pending = show
            if loadingID == nil { load(adUnitID) }
        }
    }
    private func load(_ id: String) {
        guard available else { let callback = pending; pending = nil; callback?(nil); return }
        loadingID = id
        RewardedAd.load(with: id, request: Request()) { [weak self] ad, error in
            Task { @MainActor in
                guard let self else { return }
                self.loadingID = nil
                self.ad = error == nil ? ad : nil
                self.loadedID = self.ad == nil ? nil : id
                let callback = self.pending; self.pending = nil
                callback?(self.ad)
            }
        }
    }
    private func finish(failed: Bool = false) {
        guard let previous = attempt else { return }
        pending = nil; presenting = false; presentedAd = nil
        requests.finish(previous, failed: failed)
    }
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        guard (ad as AnyObject) === presentedAd else { return }; finish()
    }
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        guard (ad as AnyObject) === presentedAd else { return }; finish(failed: true)
    }
}
