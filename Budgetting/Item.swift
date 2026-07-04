//
//  Item.swift
//  Budgetting
//
//  Created by Zacharie on 4/7/26.
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
