//
//  ParsedReceipt.swift
//  Budgetting
//
//  Created by Zacharie on 4/7/26.
//

import Foundation
import FoundationModels

@Generable
struct ParsedReceipt {

    @Guide(description: "Store name")
    var merchant: String = ""

    @Guide(description: "Short expense title")
    var title: String = ""

    @Guide(description: "Total amount paid")
    var total: Double?

    @Guide(description: "Receipt date in dd/MM/yyyy format")
    var date: String = ""

    @Guide(description: "Expense category")
    var category: String = "Other"

    @Guide(description: "Purchased items")
    var items: [String] = []

}
