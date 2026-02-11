//
//  Item.swift
//  Tikkuu Focus
//
//  Created by 梁非凡 on 2026/2/8.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
