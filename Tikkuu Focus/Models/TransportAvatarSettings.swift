//
//  TransportAvatarSettings.swift
//  Tikkuu Focus
//
//  Created by Tikkuu on 2026/2/8.
//

import Foundation
import SwiftData

@Model
final class TransportAvatarSettings {
    var id: UUID = UUID()
    var isEnabled: Bool = false
    @Attribute(.externalStorage)
    var imageData: Data? = nil
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        isEnabled: Bool = false,
        imageData: Data? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.isEnabled = isEnabled
        self.imageData = imageData
        self.updatedAt = updatedAt
    }
}

