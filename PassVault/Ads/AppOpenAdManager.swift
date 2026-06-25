//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import GoogleMobileAds
import UIKit

@MainActor
@Observable
final class AppOpenAdManager: NSObject {
    private var appOpenAd: GADAppOpenAd?
    private var isLoadingAd = false
    private var isShowingAd = false
    private var loadTime: Date?

    // Show at most once per 4-hour window — password managers open frequently
    private let adExpiryInterval: TimeInterval = 4 * 3600

    // Skip the very first cold launch — user just wants their credential
    private var hasShownFirstAd = false

    override init() {
        super.init()
        loadAd()
    }

    func loadAd() {
        guard !isLoadingAd, !isAdValid else { return }
        isLoadingAd = true
        GADAppOpenAd.load(
            withAdUnitID: AdConfig.appOpenAdUnitID,
            request: GADRequest()
        ) { [weak self] ad, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isLoadingAd = false
                if let error {
                    print("[AdMob] App open ad failed to load: \(error.localizedDescription)")
                    return
                }
                self.appOpenAd = ad
                self.appOpenAd?.fullScreenContentDelegate = self
                self.loadTime = Date()
            }
        }
    }

    private var isAdValid: Bool {
        guard appOpenAd != nil, let loadTime else { return false }
        return Date().timeIntervalSince(loadTime) < adExpiryInterval
    }

    func showAdIfAvailable() {
        guard hasShownFirstAd else {
            hasShownFirstAd = true
            loadAd()
            return
        }
        guard !isShowingAd, isAdValid else {
            if !isAdValid { loadAd() }
            return
        }
        guard
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else { return }
        isShowingAd = true
        appOpenAd?.present(fromRootViewController: root)
    }
}

extension AppOpenAdManager: GADFullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        Task { @MainActor [weak self] in
            self?.appOpenAd = nil
            self?.isShowingAd = false
            self?.loadAd()
        }
    }

    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor [weak self] in
            self?.isShowingAd = false
            self?.appOpenAd = nil
            self?.loadAd()
        }
    }
}
