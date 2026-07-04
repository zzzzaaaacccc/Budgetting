//
//  Budget.swift
//  Budgetting
//
//  Created by Zacharie on 4/7/26.
//

import Foundation
import SwiftData

@Model
final class Budget {

    var monthlyBudget: Double

    init(monthlyBudget: Double = 1000) {
        self.monthlyBudget = monthlyBudget
    }

}
