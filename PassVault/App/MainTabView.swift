//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

struct MainTabView: View {
  @State private var homeShell = HomeViewModel()
  @State private var vaultCategories = CategoriesViewModel()
  @State private var telemetry = AnalyzeViewModel()
  @State private var copyToastHost = CopyToastHost()

  var body: some View {
    TabView {
      HomePaneView(model: homeShell)
        .tabItem { Label(String(localized: "Home"), systemImage: "lock.square") }

      CategoriesPaneView(categoriesVm: vaultCategories, homeVm: homeShell)
        .tabItem { Label(String(localized: "Categories"), systemImage: "square.grid.2x2.fill") }

      AnalyzePaneView(analyze: telemetry)
        .tabItem { Label(String(localized: "Analyze"), systemImage: "chart.xyaxis.line") }

      SettingsPaneView(home: homeShell)
        .tabItem { Label(String(localized: "Settings"), systemImage: "gearshape.fill") }
    }
    .tint(Color.accentColor)
    .environment(\.copyToastHost, copyToastHost)
    .overlay {
      CopyToastOverlay(host: copyToastHost)
    }
  }
}
