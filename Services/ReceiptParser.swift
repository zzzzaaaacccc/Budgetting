//
//  ReceiptParser.swift
//  Budgetting
//
//  Created by Zacharie on 4/7/26.
//

import Foundation

final class ReceiptParser {

    func parse(text: String) -> ParsedReceipt {

        var receipt = ParsedReceipt()

        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        // Merchant
        if let first = lines.first {
            receipt.merchant = first
        }

        // Total
        receipt.total = extractTotal(from: lines)

        // Date
        receipt.date = extractDate(from: lines)

        // Items
        receipt.items = extractItems(from: lines)

        // Category
        receipt.category = suggestCategory(
            merchant: receipt.merchant,
            items: receipt.items
        )

        return receipt

    }

    private func extractTotal(from lines: [String]) -> Double? {

        let keywords = [
            "TOTAL",
            "AMOUNT",
            "NET",
            "PAY",
            "SGD",
            "$"
        ]

        for line in lines.reversed() {

            let upper = line.uppercased()

            if keywords.contains(where: upper.contains) {

                if let value = firstDecimal(in: line) {
                    return value
                }

            }

        }

        return nil

    }

    private func extractDate(from lines: [String]) -> Date? {

        let formatter = DateFormatter()

        formatter.dateFormat = "dd/MM/yyyy"

        for line in lines {

            if let date = formatter.date(from: line) {
                return date
            }

        }

        return nil

    }

    private func extractItems(from lines: [String]) -> [String] {

        lines.filter {

            !$0.contains("$")
            &&
            !$0.lowercased().contains("total")
            &&
            !$0.lowercased().contains("gst")

        }

    }

    private func suggestCategory(
        merchant: String,
        items: [String]
    ) -> String {

        let text = (merchant + " " + items.joined(separator: " "))
            .lowercased()

        if text.contains("starbucks")
            || text.contains("coffee")
            || text.contains("mcdonald")
            || text.contains("kfc")
            || text.contains("subway")
            || text.contains("toast")
            || text.contains("restaurant")
        {
            return "Food"
        }

        if text.contains("ntuc")
            || text.contains("fairprice")
            || text.contains("sheng siong")
            || text.contains("cold storage")
        {
            return "Groceries"
        }

        if text.contains("grab")
            || text.contains("comfort")
            || text.contains("taxi")
            || text.contains("mrt")
        {
            return "Transport"
        }

        return "Other"

    }

    private func firstDecimal(in text: String) -> Double? {

        let regex = try? NSRegularExpression(
            pattern: #"([0-9]+(?:\.[0-9]{2})?)"#
        )

        guard
            let match = regex?.firstMatch(
                in: text,
                range: NSRange(
                    text.startIndex...,
                    in: text
                )
            ),
            let range = Range(match.range(at: 1), in: text)
        else {
            return nil
        }

        return Double(text[range])

    }

}
