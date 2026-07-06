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

    @Attribute(.externalStorage)
    var receiptImage: Data?

    var receiptText: String?
    var receiptItems: [String]?

    init(
        title: String,
        merchant: String,
        amount: Double,
        category: String,
        date: Date = .now,
        receiptImage: Data? = nil,
        receiptText: String? = nil,
        receiptItems: [String]? = nil
    ) {
        self.title = title
        self.merchant = merchant
        self.amount = amount
        self.category = category
        self.date = date
        self.receiptImage = receiptImage
        self.receiptText = receiptText
        self.receiptItems = receiptItems
    }
}
