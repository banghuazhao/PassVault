//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import GoogleMobileAds
import SwiftUI
import UIKit

struct BannerAdView: UIViewRepresentable {
    let adUnitID: String
    @Binding var adHeight: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(adHeight: $adHeight)
    }

    func makeUIView(context: Context) -> GADBannerView {
        let width = UIScreen.main.bounds.width
        let adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(width)
        DispatchQueue.main.async { adHeight = adSize.size.height }
        let banner = GADBannerView(adSize: adSize)
        banner.adUnitID = adUnitID
        banner.delegate = context.coordinator
        banner.rootViewController = keyWindowRootVC()
        banner.load(GADRequest())
        return banner
    }

    func updateUIView(_ banner: GADBannerView, context: Context) {
        banner.rootViewController = keyWindowRootVC()
    }

    private func keyWindowRootVC() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
    }

    final class Coordinator: NSObject, GADBannerViewDelegate {
        @Binding var adHeight: CGFloat

        init(adHeight: Binding<CGFloat>) {
            _adHeight = adHeight
        }

        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            DispatchQueue.main.async {
                self.adHeight = bannerView.adSize.size.height
            }
        }
    }
}
