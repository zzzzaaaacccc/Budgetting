//
//  ReceiptParser.swift
//  Budgetting
//
//  Created by Zacharie on 4/7/26.
//

import Foundation

enum ReceiptParser {

    static func parse(_ text: String) -> ParsedReceipt {

        let lines = text
            .components(separatedBy: .newlines)
            .map {
                $0.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            }
            .filter {
                !$0.isEmpty
            }

        let merchant = extractMerchant(from: lines)
        let date = extractDate(from: text)
        let subtotal = extractAmount(
            from: lines,
            matching: [
                "subtotal",
                "sub total"
            ]
        )
        let tax = extractAmount(
            from: lines,
            matching: [
                "gst",
                "tax"
            ]
        )
        let total = extractTotal(from: lines)
        let category = categorise(
            merchant: merchant,
            text: text
        )

        return ParsedReceipt(
            merchant: merchant,
            title: merchant == "Unknown Merchant"
                ? "Receipt Expense"
                : merchant,
            total: total,
            date: date,
            category: category,
            items: extractItems(from: lines),
            subtotal: subtotal,
            tax: tax,
            rawText: text
        )
    }

    private static func extractMerchant(
        from lines: [String]
    ) -> String {

        let ignoredKeywords = [
            "receipt",
            "invoice",
            "tax invoice",
            "welcome",
            "thank you",
            "gst registration",
            "company registration"
        ]

        for line in lines.prefix(8) {

            let lowercaseLine = line.lowercased()

            let shouldIgnore = ignoredKeywords.contains {
                lowercaseLine.contains($0)
            }

            let containsLetters = line.rangeOfCharacter(
                from: .letters
            ) != nil

            let containsTooManyNumbers =
                line.filter(\.isNumber).count >
                line.filter(\.isLetter).count

            if containsLetters &&
                !shouldIgnore &&
                !containsTooManyNumbers {

                return line
            }
        }

        return "Unknown Merchant"
    }

    private static func extractDate(
        from text: String
    ) -> String {

        let patterns = [
            #"\b\d{1,2}/\d{1,2}/\d{2,4}\b"#,
            #"\b\d{1,2}-\d{1,2}-\d{2,4}\b"#,
            #"\b\d{4}-\d{1,2}-\d{1,2}\b"#,
            #"\b\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{2,4}\b"#
        ]

        for pattern in patterns {

            if let date = firstMatch(
                pattern: pattern,
                in: text,
                options: [.caseInsensitive]
            ) {
                return date
            }
        }

        return ""
    }

    private static func extractTotal(
        from lines: [String]
    ) -> Double? {

        let preferredKeywords = [
            "grand total",
            "amount due",
            "total due",
            "net total",
            "total"
        ]

        for keyword in preferredKeywords {

            if let amount = extractAmount(
                from: lines,
                matching: [keyword]
            ) {
                return amount
            }
        }

        let possibleAmounts = lines.compactMap {
            extractLastAmount(from: $0)
        }

        return possibleAmounts.max()
    }

    private static func extractAmount(
        from lines: [String],
        matching keywords: [String]
    ) -> Double? {

        for line in lines.reversed() {

            let lowercaseLine = line.lowercased()

            let containsKeyword = keywords.contains {
                lowercaseLine.contains($0)
            }

            guard containsKeyword else {
                continue
            }

            if let amount = extractLastAmount(
                from: line
            ) {
                return amount
            }
        }

        return nil
    }

    private static func extractLastAmount(
        from text: String
    ) -> Double? {

        let pattern =
            #"(?:S\$|SGD|\$)?\s*(\d{1,6}(?:[.,]\d{2}))"#

        guard let expression = try? NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive]
        ) else {
            return nil
        }

        let range = NSRange(
            text.startIndex..<text.endIndex,
            in: text
        )

        let matches = expression.matches(
            in: text,
            range: range
        )

        guard let match = matches.last,
              let amountRange = Range(
                match.range(at: 1),
                in: text
              )
        else {
            return nil
        }

        let amountString = String(
            text[amountRange]
        )
        .replacingOccurrences(
            of: ",",
            with: "."
        )

        return Double(amountString)
    }

    private static func categorise(
        merchant: String,
        text: String
    ) -> String {

        let searchableText =
            "\(merchant) \(text)".lowercased()

        let categoryKeywords: [String: [String]] = [
            "Food & Dining": [
                "restaurant",
                "cafe",
                "coffee",
                "mcdonald",
                "kfc",
                "starbucks",
                "food",
                "dining",
                "bakery"
            ],
            "Groceries": [
                "fairprice",
                "ntuc",
                "sheng siong",
                "cold storage",
                "giant",
                "supermarket",
                "grocery"
            ],
            "Transport": [
                "grab",
                "gojek",
                "comfortdelgro",
                "taxi",
                "mrt",
                "transit",
                "parking",
                "petrol",
                "shell",
                "esso"
            ],
            "Healthcare": [
                "guardian",
                "watsons",
                "pharmacy",
                "clinic",
                "hospital",
                "medical",
                "dental"
            ],
            "Shopping": [
                "uniqlo",
                "shopee",
                "lazada",
                "amazon",
                "retail",
                "department store"
            ],
            "Entertainment": [
                "cinema",
                "movie",
                "netflix",
                "spotify",
                "entertainment"
            ],
            "Utilities": [
                "electricity",
                "water",
                "internet",
                "mobile",
                "utilities",
                "singtel",
                "starhub",
                "m1"
            ]
        ]

        for (category, keywords) in categoryKeywords {

            if keywords.contains(where: {
                searchableText.contains($0)
            }) {
                return category
            }
        }

        return "Uncategorised"
    }
    
    private static func extractItems(
        from lines: [String]
    ) -> [String] {

        let ignoredKeywords = [
            "subtotal",
            "sub total",
            "total",
            "grand total",
            "amount due",
            "gst",
            "tax",
            "change",
            "cash",
            "visa",
            "mastercard",
            "nets",
            "receipt",
            "invoice",
            "thank you",
            "date",
            "time",
            "cashier",
            "tel",
            "phone",
            "address",
            "company registration"
        ]

        return lines
            .dropFirst(min(3, lines.count))
            .compactMap { line in

                let lowercasedLine = line.lowercased()

                guard !ignoredKeywords.contains(
                    where: {
                        lowercasedLine.contains($0)
                    }
                ) else {
                    return nil
                }

                guard line.rangeOfCharacter(
                    from: .letters
                ) != nil else {
                    return nil
                }

                let cleanedItem = line
                    .replacingOccurrences(
                        of: #"(?:S\$|SGD|\$)?\s*\d+(?:[.,]\d{2})$"#,
                        with: "",
                        options: .regularExpression
                    )
                    .replacingOccurrences(
                        of: #"^\d+\s*[xX]\s*"#,
                        with: "",
                        options: .regularExpression
                    )
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

                guard cleanedItem.count >= 2 else {
                    return nil
                }

                return cleanedItem
            }
    }
    
    private static func firstMatch(
        pattern: String,
        in text: String,
        options: NSRegularExpression.Options = []
    ) -> String? {

        guard let expression = try? NSRegularExpression(
            pattern: pattern,
            options: options
        ) else {
            return nil
        }

        let range = NSRange(
            text.startIndex..<text.endIndex,
            in: text
        )

        guard let match = expression.firstMatch(
            in: text,
            range: range
        ),
              let matchRange = Range(
                match.range,
                in: text
              )
        else {
            return nil
        }

        return String(text[matchRange])
    }
}
