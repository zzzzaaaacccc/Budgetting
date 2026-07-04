//
//  Expense.swift
//  Budgetting
//
//  Created by Zacharie on 4/7/26.
//

import Foundation
import SwiftData

@Model
final class Expense {

    var title: String
    var merchant: String
    var amount: Double
    var category: String
    var date: Date

    init(
        title: String,
        merchant: String,
        amount: Double,
        category: String,
        date: Date = .now
    ) {
        self.title = title
        self.merchant = merchant
        self.amount = amount
        self.category = category
        self.date = date
    }

}
