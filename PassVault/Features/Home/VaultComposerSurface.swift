//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SQLiteData

enum VaultComposerSurface: Identifiable {

  case compose(categoryHint: Int?)
  case amend(VaultPasswordRow)

  var id: String {

    switch self {

    case let .compose(hint):

      return "compose-\(hint.map(String.init(describing:)) ?? "nil")"

    case let .amend(row):

      return "amend-\(row.id)"

    }

  }

}
