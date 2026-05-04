//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import SQLiteData

@Table("categories")
nonisolated struct CategoryRow: Identifiable, Hashable {
  let id: Int
  var name: String
  var iconSFName: String
  var sortOrder: Int
}
