//
//  AppleIntelligenceReceiptParser.swift
//  Budgetting
//
//  Created by Zacharie on 6/7/26.
//


import Foundation
import FoundationModels

@available(iOS 26.0, macOS 26.0, *)
final class AppleIntelligenceReceiptParser {

    private let model =
        SystemLanguageModel.default

    var isAvailable: Bool {

        model.isAvailable
    }

    func parseReceipt(
        from ocrText: String
    ) async throws -> ParsedReceipt {

        guard model.isAvailable else {

            throw AppleIntelligenceReceiptParserError
                .modelUnavailable
        }

        let cleanedText =
            cleanOCRText(ocrText)

        guard !cleanedText.isEmpty else {

            throw AppleIntelligenceReceiptParserError
                .emptyOCRText
        }

        /*
         First, parse the full receipt in smaller sections.

         Each section uses a fresh session so its context
         does not accumulate across the entire receipt.
         */

        let chunks =
            splitIntoChunks(
                cleanedText,
                maximumCharacters: 3_000
            )

        var partialReceipts: [PartialReceipt] = []

        for (index, chunk) in chunks.enumerated() {

            try Task.checkCancellation()

            let partialReceipt =
                try await parseChunk(
                    chunk,
                    chunkNumber: index + 1,
                    totalChunks: chunks.count
                )

            partialReceipts.append(
                partialReceipt
            )
        }

        /*
         Combine non-payment information such as merchant,
         title, category and purchased items.
         */

        var receipt =
            try await combinePartialReceipts(
                partialReceipts
            )

        try Task.checkCancellation()

        /*
         Run a separate focused AI pass for monetary values.

         The model returns exact labels, amount strings and
         supporting OCR lines rather than calculated totals.
         */

        let paymentSummary =
            try await extractPaymentSummary(
                from: cleanedText
            )

        /*
         Verify the AI-selected values against the original OCR.

         Unverified values become nil instead of showing a
         confident but incorrect amount.
         */

        let verifiedPayment =
            verifyPaymentSummary(
                paymentSummary,
                against: cleanedText
            )

        receipt.total =
            verifiedPayment.total

        receipt.subtotal =
            verifiedPayment.subtotal

        receipt.tax =
            verifiedPayment.tax

        receipt.items =
            removeDuplicateItems(
                receipt.items
            )

        receipt.rawText =
            cleanedText

        return receipt
    }

    // MARK: - Chunk Parsing

    private func parseChunk(
        _ chunk: String,
        chunkNumber: Int,
        totalChunks: Int
    ) async throws -> PartialReceipt {

        let session =
            LanguageModelSession(
                model: model,
                instructions: """
                Extract structured information from one section
                of OCR text belonging to a purchase receipt.

                Return only information that is explicitly supported
                by the supplied OCR section.

                Rules:

                - Do not invent missing information.
                - The merchant is the business that issued the receipt.
                - Extract only genuine purchased products or services.
                - Exclude addresses and telephone numbers.
                - Exclude registration numbers and invoice identifiers.
                - Exclude payment methods and masked card numbers.
                - Exclude totals, subtotals, GST and tax lines from items.
                - Exclude fees, discounts and promotional explanations.
                - Exclude loyalty points and terms and conditions.
                - Do not calculate monetary values.
                - Supermarkets, including FairPrice, are Groceries.
                """
            )

        let response =
            try await session.respond(
                to: """
                This is section \(chunkNumber) of \(totalChunks)
                from the same receipt.

                Extract useful receipt information from this section.

                OCR section:

                \(chunk)
                """,
                generating: PartialReceipt.self,
                includeSchemaInPrompt: true
            )

        return response.content
    }

    // MARK: - Receipt Consolidation

    private func combinePartialReceipts(
        _ partialReceipts: [PartialReceipt]
    ) async throws -> ParsedReceipt {

        let compactResults =
            partialReceipts
                .enumerated()
                .map { index, receipt in

                    """
                    Section \(index + 1):

                    Merchant:
                    \(receipt.merchant ?? "")

                    Title:
                    \(receipt.title ?? "")

                    Date:
                    \(receipt.date ?? "")

                    Category:
                    \(receipt.category ?? "")

                    Purchased items:
                    \(receipt.items.joined(separator: " | "))
                    """
                }
                .joined(
                    separator: "\n\n"
                )

        let session =
            LanguageModelSession(
                model: model,
                instructions: """
                Combine partial receipt extraction results into
                one structured receipt.

                Rules:

                - Do not invent missing information.
                - Prefer the business name found near the beginning.
                - Create a short and useful expense title.
                - Preserve genuine purchased products.
                - Remove duplicate items.
                - Exclude fees, totals, tax, addresses and metadata.
                - Return the date as dd/MM/yyyy where possible.
                - Supermarkets and FairPrice are Groceries.
                - Restaurants and cafés are Food.
                - Taxis, ride-hailing and public transport are Transport.
                - Pharmacies and clinics are Healthcare.
                - Utilities and telecommunications are Bills.
                - General retail purchases are Shopping.
                - Use exactly one category:
                  Food,
                  Groceries,
                  Transport,
                  Shopping,
                  Entertainment,
                  Healthcare,
                  Bills,
                  Other.
                - Set total, subtotal and tax to nil.
                  These fields are handled by a dedicated payment pass.
                - Set rawText to an empty string.
                  The application assigns it after generation.
                """
            )

        let response =
            try await session.respond(
                to: """
                Consolidate these partial receipt results:

                \(compactResults)
                """,
                generating: ParsedReceipt.self,
                includeSchemaInPrompt: true
            )

        var receipt =
            response.content

        /*
         Do not trust payment values from the general
         consolidation pass.
         */

        receipt.total = nil
        receipt.subtotal = nil
        receipt.tax = nil
        receipt.rawText = ""

        return receipt
    }

    // MARK: - Payment Extraction

    private func extractPaymentSummary(
        from ocrText: String
    ) async throws -> ReceiptPaymentSummary {

        let relevantText =
            paymentRelevantLines(
                from: ocrText
            )

        let session =
            LanguageModelSession(
                model: model,
                instructions: """
                Locate explicitly labelled payment information
                within receipt OCR text.

                This is an evidence-extraction task.

                Do not perform arithmetic.

                Critical rules:

                - Copy labels exactly from the supplied OCR text.
                - Copy monetary text exactly from the supplied OCR text.
                - Do not calculate a final total.
                - Never add subtotal and tax.
                - Never add GST to a displayed total.
                - GST may already be included in displayed prices.
                - Never use Subtotal as the final amount.
                - Never use an individual item price as the final amount.
                - Never use a discount as the final amount.
                - Prefer final labels such as:
                  Order total,
                  Grand total,
                  Amount paid,
                  Total paid,
                  Final total,
                  Net total,
                  Payment total.
                - A percentage such as 9% GST is not a monetary tax amount.
                - Return an empty string when reliable evidence is absent.
                """
            )

        let response =
            try await session.respond(
                to: """
                Extract the exact payment evidence from this OCR text.

                OCR text:

                \(relevantText)
                """,
                generating: ReceiptPaymentSummary.self,
                includeSchemaInPrompt: true
            )

        return response.content
    }

    // MARK: - Payment Verification

    private func verifyPaymentSummary(
        _ summary: ReceiptPaymentSummary,
        against ocrText: String
    ) -> VerifiedPaymentSummary {

        let verifiedTotal =
            verifyFinalTotal(
                label: summary.finalTotalLabel,
                amountText:
                    summary.finalTotalAmountText,
                evidence:
                    summary.finalTotalEvidence,
                ocrText: ocrText
            )

        let verifiedSubtotal =
            verifyLabelledAmount(
                label: summary.subtotalLabel,
                amountText:
                    summary.subtotalAmountText,
                acceptedLabels: [
                    "subtotal",
                    "fairprice subtotal",
                    "sub total"
                ],
                ocrText: ocrText
            )

        let verifiedTax =
            verifyTaxAmount(
                label: summary.taxLabel,
                amountText:
                    summary.taxAmountText,
                ocrText: ocrText
            )

        return VerifiedPaymentSummary(
            total: verifiedTotal,
            subtotal: verifiedSubtotal,
            tax: verifiedTax
        )
    }

    private func verifyFinalTotal(
        label: String,
        amountText: String,
        evidence: String,
        ocrText: String
    ) -> Double? {

        let cleanedLabel =
            label.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let cleanedAmount =
            amountText.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !cleanedLabel.isEmpty,
              !cleanedAmount.isEmpty
        else {

            return nil
        }

        let allowedLabels = [
            "order total",
            "grand total",
            "amount paid",
            "total paid",
            "final total",
            "net total",
            "payment total",
            "total payment paid"
        ]

        let normalisedLabel =
            normaliseForComparison(
                cleanedLabel
            )

        let hasAllowedLabel =
            allowedLabels.contains {
                normalisedLabel.contains($0)
            }

        guard hasAllowedLabel else {

            return nil
        }

        let normalisedOCR =
            normaliseForComparison(
                ocrText
            )

        let normalisedAmount =
            normaliseForComparison(
                cleanedAmount
            )

        guard normalisedOCR.contains(
            normalisedLabel
        ),
        normalisedOCR.contains(
            normalisedAmount
        )
        else {

            return nil
        }

        /*
         Evidence improves confidence, but OCR may separate
         the label and amount across distant lines. Therefore,
         do not reject an otherwise valid result solely because
         the model's evidence block is formatted differently.
         */

        let cleanedEvidence =
            evidence.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if !cleanedEvidence.isEmpty {

            let evidenceTerms =
                normaliseForComparison(
                    cleanedEvidence
                )

            let evidenceContainsLabel =
                evidenceTerms.contains(
                    normalisedLabel
                )

            let evidenceContainsAmount =
                evidenceTerms.contains(
                    normalisedAmount
                )

            guard evidenceContainsLabel,
                  evidenceContainsAmount
            else {

                return nil
            }
        }

        return parseCurrencyAmount(
            cleanedAmount
        )
    }

    private func verifyLabelledAmount(
        label: String,
        amountText: String,
        acceptedLabels: [String],
        ocrText: String
    ) -> Double? {

        let cleanedLabel =
            label.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let cleanedAmount =
            amountText.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !cleanedLabel.isEmpty,
              !cleanedAmount.isEmpty
        else {

            return nil
        }

        let normalisedLabel =
            normaliseForComparison(
                cleanedLabel
            )

        let labelIsAccepted =
            acceptedLabels.contains {
                normalisedLabel.contains($0)
            }

        guard labelIsAccepted else {

            return nil
        }

        let normalisedOCR =
            normaliseForComparison(
                ocrText
            )

        let normalisedAmount =
            normaliseForComparison(
                cleanedAmount
            )

        guard normalisedOCR.contains(
            normalisedLabel
        ),
        normalisedOCR.contains(
            normalisedAmount
        )
        else {

            return nil
        }

        return parseCurrencyAmount(
            cleanedAmount
        )
    }

    private func verifyTaxAmount(
        label: String,
        amountText: String,
        ocrText: String
    ) -> Double? {

        let cleanedLabel =
            label.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let cleanedAmount =
            amountText.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !cleanedLabel.isEmpty,
              !cleanedAmount.isEmpty
        else {

            return nil
        }

        guard !cleanedAmount.contains("%") else {

            return nil
        }

        let normalisedLabel =
            normaliseForComparison(
                cleanedLabel
            )

        let isTaxLabel =
            normalisedLabel.contains("gst") ||
            normalisedLabel.contains("tax")

        guard isTaxLabel else {

            return nil
        }

        let normalisedOCR =
            normaliseForComparison(
                ocrText
            )

        let normalisedAmount =
            normaliseForComparison(
                cleanedAmount
            )

        guard normalisedOCR.contains(
            normalisedLabel
        ),
        normalisedOCR.contains(
            normalisedAmount
        )
        else {

            return nil
        }

        return parseCurrencyAmount(
            cleanedAmount
        )
    }

    // MARK: - Payment Text Selection

    private func paymentRelevantLines(
        from text: String
    ) -> String {

        let keywords = [
            "subtotal",
            "sub total",
            "order total",
            "grand total",
            "amount paid",
            "total paid",
            "final total",
            "net total",
            "payment total",
            "total payment",
            "service fee",
            "delivery fee",
            "cart discount",
            "discount",
            "promotion",
            "promo",
            "voucher",
            "gst",
            "tax",
            "free"
        ]

        let lines =
            text
                .components(
                    separatedBy: .newlines
                )
                .map {
                    $0.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                }
                .filter {
                    !$0.isEmpty
                }

        guard !lines.isEmpty else {

            return text
        }

        var selectedIndexes: Set<Int> = []

        for (index, line) in lines.enumerated() {

            let lowercasedLine =
                line.lowercased()

            let containsKeyword =
                keywords.contains {
                    lowercasedLine.contains($0)
                }

            guard containsKeyword else {

                continue
            }

            /*
             OCR may place labels and amounts on separate lines,
             so include several surrounding lines.
             */

            let lowerBound =
                max(
                    0,
                    index - 4
                )

            let upperBound =
                min(
                    lines.count - 1,
                    index + 5
                )

            for nearbyIndex in
                lowerBound...upperBound {

                selectedIndexes.insert(
                    nearbyIndex
                )
            }
        }

        guard !selectedIndexes.isEmpty else {

            return lines
                .suffix(100)
                .joined(separator: "\n")
        }

        return selectedIndexes
            .sorted()
            .map {
                lines[$0]
            }
            .joined(separator: "\n")
    }

    // MARK: - OCR Cleaning

    private func cleanOCRText(
        _ text: String
    ) -> String {

        text
            .components(
                separatedBy: .newlines
            )
            .map {
                $0.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            }
            .filter {
                !$0.isEmpty
            }
            .joined(separator: "\n")
    }

    // MARK: - Chunking

    private func splitIntoChunks(
        _ text: String,
        maximumCharacters: Int
    ) -> [String] {

        let lines =
            text.components(
                separatedBy: .newlines
            )

        var chunks: [String] = []

        var currentChunk = ""

        for line in lines {

            let candidate: String

            if currentChunk.isEmpty {

                candidate = line

            } else {

                candidate =
                    currentChunk +
                    "\n" +
                    line
            }

            if candidate.count <=
                maximumCharacters {

                currentChunk =
                    candidate

                continue
            }

            if !currentChunk.isEmpty {

                chunks.append(
                    currentChunk
                )
            }

            if line.count >
                maximumCharacters {

                let longLineChunks =
                    splitLongLine(
                        line,
                        maximumCharacters:
                            maximumCharacters
                    )

                if longLineChunks.count > 1 {

                    chunks.append(
                        contentsOf:
                            longLineChunks.dropLast()
                    )
                }

                currentChunk =
                    longLineChunks.last ?? ""

            } else {

                currentChunk =
                    line
            }
        }

        if !currentChunk.isEmpty {

            chunks.append(
                currentChunk
            )
        }

        return chunks
    }

    private func splitLongLine(
        _ line: String,
        maximumCharacters: Int
    ) -> [String] {

        var results: [String] = []

        var currentIndex =
            line.startIndex

        while currentIndex <
            line.endIndex {

            let endIndex =
                line.index(
                    currentIndex,
                    offsetBy:
                        maximumCharacters,
                    limitedBy:
                        line.endIndex
                ) ?? line.endIndex

            results.append(
                String(
                    line[
                        currentIndex..<endIndex
                    ]
                )
            )

            currentIndex =
                endIndex
        }

        return results
    }

    // MARK: - Item Cleaning

    private func removeDuplicateItems(
        _ items: [String]
    ) -> [String] {

        var encounteredItems:
            Set<String> = []

        return items.compactMap { item in

            let cleanedItem =
                item.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

            guard !cleanedItem.isEmpty else {

                return nil
            }

            let comparisonValue =
                cleanedItem.lowercased()

            guard !encounteredItems.contains(
                comparisonValue
            ) else {

                return nil
            }

            encounteredItems.insert(
                comparisonValue
            )

            return cleanedItem
        }
    }

    // MARK: - Amount Parsing

    private func parseCurrencyAmount(
        _ text: String
    ) -> Double? {

        var cleaned =
            text
                .replacingOccurrences(
                    of: ",",
                    with: ""
                )
                .replacingOccurrences(
                    of: "S$",
                    with: "",
                    options: .caseInsensitive
                )
                .replacingOccurrences(
                    of: "$",
                    with: ""
                )
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        /*
         Correct a few common OCR substitutions only when
         they appear inside a monetary string.
         */

        cleaned =
            cleaned
                .replacingOccurrences(
                    of: "O",
                    with: "0"
                )
                .replacingOccurrences(
                    of: "o",
                    with: "0"
                )

        let pattern =
            #"-?\d+(?:\.\d{1,2})?"#

        guard let range =
            cleaned.range(
                of: pattern,
                options: .regularExpression
            )
        else {

            return nil
        }

        return Double(
            String(
                cleaned[range]
            )
        )
    }

    private func normaliseForComparison(
        _ text: String
    ) -> String {

        text
            .lowercased()
            .replacingOccurrences(
                of: "*",
                with: ""
            )
            .replacingOccurrences(
                of: ":",
                with: ""
            )
            .components(
                separatedBy:
                    .whitespacesAndNewlines
            )
            .filter {
                !$0.isEmpty
            }
            .joined(separator: " ")
    }
}

// MARK: - Partial Receipt

@available(iOS 26.0, macOS 26.0, *)
@Generable
struct PartialReceipt {

    @Guide(
        description:
            """
            The merchant or business name explicitly present
            in this OCR section.

            Do not return an address, invoice heading,
            payment provider or product name.
            """
    )
    var merchant: String?

    @Guide(
        description:
            """
            A short expense title based only on information
            explicitly present in this OCR section.
            """
    )
    var title: String?

    @Guide(
        description:
            """
            The receipt or transaction date in dd/MM/yyyy format
            when explicitly present.

            Return an empty value when no reliable date exists.
            """
    )
    var date: String?

    @Guide(
        description:
            """
            The likely expense category.

            FairPrice and other supermarkets are Groceries.
            """
    )
    var category: String?

    @Guide(
        description:
            """
            Genuine purchased product or service names explicitly
            present in this OCR section.

            Exclude totals, tax, fees, discounts, payment details,
            addresses, metadata and promotional explanations.
            """
    )
    var items: [String]
}

// MARK: - Payment Summary

@available(iOS 26.0, macOS 26.0, *)
@Generable
struct ReceiptPaymentSummary {

    @Guide(
        description:
            """
            Copy the exact final-total label from the OCR text.

            Valid examples include:
            Order total
            Grand total
            Amount paid
            Total paid
            Final total
            Net total

            Never return Subtotal.

            Return an empty string if no explicit final-total
            label is present.
            """
    )
    var finalTotalLabel: String

    @Guide(
        description:
            """
            Copy the exact monetary amount associated with
            finalTotalLabel from the OCR text.

            Example:
            $64.64

            Do not calculate or modify the amount.

            Return an empty string when absent.
            """
    )
    var finalTotalAmountText: String

    @Guide(
        description:
            """
            Copy the exact OCR lines supporting the final total,
            including both its label and monetary amount.

            Do not paraphrase or calculate.
            """
    )
    var finalTotalEvidence: String

    @Guide(
        description:
            """
            Copy the exact subtotal label from the OCR text.

            Examples:
            Subtotal
            FairPrice subtotal

            Return an empty string when absent.
            """
    )
    var subtotalLabel: String

    @Guide(
        description:
            """
            Copy the exact monetary subtotal associated with
            subtotalLabel.

            Do not calculate the subtotal.

            Return an empty string when absent.
            """
    )
    var subtotalAmountText: String

    @Guide(
        description:
            """
            Copy the exact GST or tax label associated with
            a separately displayed monetary tax amount.

            Return an empty string when the receipt only displays
            a percentage or states that GST is included.
            """
    )
    var taxLabel: String

    @Guide(
        description:
            """
            Copy the exact separately displayed monetary GST
            or tax amount.

            Do not calculate tax from a percentage.

            Return an empty string when no monetary tax amount
            is explicitly displayed.
            """
    )
    var taxAmountText: String
}

// MARK: - Verified Payment

private struct VerifiedPaymentSummary {

    let total: Double?

    let subtotal: Double?

    let tax: Double?
}

// MARK: - Errors

enum AppleIntelligenceReceiptParserError:
    LocalizedError {

    case modelUnavailable

    case emptyOCRText

    var errorDescription: String? {

        switch self {

        case .modelUnavailable:

            return """
            Apple Intelligence is unavailable on this device.
            """

        case .emptyOCRText:

            return """
            No readable OCR text was available for parsing.
            """
        }
    }
}
