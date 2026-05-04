//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

/// Value-based navigation for vault rows (`Int` alone collides with category IDs inside the Categories tab stack).
struct PassVaultCredentialNavID: Hashable, Sendable {
  let credentialId: Int
}

/// Opens a folder’s credential list inside the Categories tab.
struct PassVaultCategoryShelfNavID: Hashable, Sendable {
  let categoryId: Int
}
