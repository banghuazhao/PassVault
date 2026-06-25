//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

enum AdConfig {
    static var bannerAdUnitID: String {
        Bundle.main.object(forInfoDictionaryKey: "BannerAdUnitID") as? String ?? ""
    }

    static var appOpenAdUnitID: String {
        Bundle.main.object(forInfoDictionaryKey: "AppOpenAdUnitID") as? String ?? ""
    }
}
