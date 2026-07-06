//
//  AIReceiptParser.swift
//  Budgetting
//
//  Created by Zacharie on 4/7/26.
//

import Foundation

struct ReceiptExtraction: Codable {

    let merchant: String

    let total: Double?

    let category: String

    let items: [String]

}

final class AIReceiptParser {

    func parse(text: String) async throws -> ReceiptExtraction {

        // Placeholder

        return ReceiptExtraction(
            merchant: "",
            total: nil,
            category: "",
            items: []
        )

    }

}
