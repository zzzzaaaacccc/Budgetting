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
            .map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter {
                !$0.isEmpty
            }

        receipt.merchant = extractMerchant(from: lines)

        receipt.total = extractTotal(from: lines)

        receipt.date = extractDateString(from: lines)

        receipt.items = extractItems(from: lines)

        receipt.category = suggestCategory(
            merchant: receipt.merchant,
            items: receipt.items
        )

        receipt.title = suggestTitle(
            merchant: receipt.merchant,
            category: receipt.category
        )

        return receipt

    }

    // MARK: Merchant

    private func extractMerchant(from lines: [String]) -> String {

        let text = lines.joined(separator: " ").uppercased()

        if text.contains("SHENG") || text.contains("SENG") {
            return "Sheng Siong"
        }

        if text.contains("STARBUCKS") {
            return "Starbucks"
        }

        if text.contains("NTUC") || text.contains("FAIRPRICE") {
            return "NTUC FairPrice"
        }

        if text.contains("MCDONALD") {
            return "McDonald's"
        }

        if text.contains("KFC") {
            return "KFC"
        }

        if text.contains("SUBWAY") {
            return "Subway"
        }

        if text.contains("GRAB") {
            return "Grab"
        }

        return lines.first ?? "Unknown"

    }

    // MARK: Total

    private func extractTotal(from lines: [String]) -> Double? {

        let regex = try! NSRegularExpression(
            pattern: #"([0-9]+\.[0-9]{2})"#
        )

        var largest: Double?

        for line in lines {

            let upper = line.uppercased()

            if upper.contains("TOTAL")
                || upper.contains("AMOUNT")
                || upper.contains("PAYABLE")
            {

                let matches = regex.matches(
                    in: line,
                    range: NSRange(
                        line.startIndex...,
                        in: line
                    )
                )

                for match in matches {

                    if let range = Range(match.range(at: 1), in: line) {

                        let value = Double(line[range])

                        if largest == nil || value! > largest! {

                            largest = value

                        }

                    }

                }

            }

        }

        return largest

    }

    // MARK: Date

    private func extractDateString(from lines: [String]) -> String {

        let patterns = [
            #"\d{2}/\d{2}/\d{4}"#,
            #"\d{2}-\d{2}-\d{4}"#,
            #"\d{4}/\d{2}/\d{2}"#,
            #"\d{4}-\d{2}-\d{2}"#
        ]

        for line in lines {

            for pattern in patterns {

                if let regex = try? NSRegularExpression(pattern: pattern),
                   let match = regex.firstMatch(
                        in: line,
                        range: NSRange(line.startIndex..., in: line)
                   ),
                   let range = Range(match.range, in: line) {

                    return String(line[range])

                }

            }

        }

        return ""

    }

    // MARK: Items

    private func extractItems(from lines: [String]) -> [String] {

        var items: [String] = []

        let excludedKeywords = [

            "TOTAL",
            "SUB TOTAL",
            "AMOUNT",
            "GST",
            "CASHIER",
            "CHANGE",
            "RECEIPT",
            "TAX",
            "DISCOUNT",
            "CARD",
            "MASTERCARD",
            "VISA",
            "NETS",
            "THANK",
            "PHONE",
            "TEL",
            "FAX",
            "DATE",
            "TIME",
            "QTY"

        ]

        for line in lines {

            let text = line.trimmingCharacters(in: .whitespaces)

            if text.count < 4 {
                continue
            }

            if excludedKeywords.contains(where: {
                text.uppercased().contains($0)
            }) {
                continue
            }

            if text.range(of: #"^\d+(\.\d+)?$"#, options: .regularExpression) != nil {
                continue
            }

            if text.range(of: #"^\d+$"#, options: .regularExpression) != nil {
                continue
            }

            if text.contains("$") {
                continue
            }

            if text.range(of: #"\d{10,}"#, options: .regularExpression) != nil {
                continue
            }

            let letters = text.filter(\.isLetter)

            if letters.count < 3 {
                continue
            }

            items.append(text)

        }

        return Array(Set(items)).sorted()

    }

    // MARK: Category

    private func suggestCategory(
        merchant: String,
        items: [String]
    ) -> String {

        let text = (merchant + " " + items.joined(separator: " "))
            .lowercased()

        if text.contains("sheng")
            || text.contains("ntuc")
            || text.contains("fairprice")
            || text.contains("grocery")
        {

            return "Groceries"

        }

        if text.contains("starbucks")
            || text.contains("coffee")
            || text.contains("restaurant")
            || text.contains("kfc")
            || text.contains("mcdonald")
        {

            return "Food"

        }

        if text.contains("grab")
            || text.contains("taxi")
            || text.contains("mrt")
        {

            return "Transport"

        }

        return "Other"

    }

    // MARK: Title

    private func suggestTitle(
        merchant: String,
        category: String
    ) -> String {

        switch category {

        case "Groceries":
            return "Grocery Shopping"

        case "Food":
            return "Meal"

        case "Transport":
            return "Transport"

        default:
            return merchant

        }

    }

}
