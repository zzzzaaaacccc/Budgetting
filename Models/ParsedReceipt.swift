//
//  ParsedReceipt.swift
//  Budgetting
//
//  Created by Zacharie on 4/7/26.
//

import Foundation

struct ParsedReceipt {

    var merchant: String = ""

    var total: Double?

    var date: Date?

    var category: String = "Other"

    var items: [String] = []

}
