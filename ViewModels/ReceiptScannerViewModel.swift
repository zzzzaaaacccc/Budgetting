//
//  ReceiptScannerViewModel.swift
//  Budgetting
//
//  Created by Zacharie on 4/7/26.
//

import Combine
import Foundation

@MainActor
final class ReceiptScannerViewModel: ObservableObject {

    @Published var image: PlatformImage?

    @Published var extractedText = ""

    @Published var receipt = ParsedReceipt.empty

    @Published var isProcessing = false

    @Published var errorMessage: String?

    @Published var parsingMethod = ""

    private var processingTask: Task<Void, Never>?

    func setImage(
        _ image: PlatformImage
    ) {

        processingTask?.cancel()

        self.image = image

        extractedText = ""

        receipt = .empty

        errorMessage = nil

        parsingMethod = ""

        processingTask = Task {

            await processReceipt()
        }
    }

    func clearReceipt() {

        processingTask?.cancel()

        processingTask = nil

        image = nil

        extractedText = ""

        receipt = .empty

        errorMessage = nil

        parsingMethod = ""

        isProcessing = false
    }

    func retryParsing() {

        guard !extractedText
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty
        else {

            errorMessage =
                "There is no OCR text available to parse."

            return
        }

        processingTask?.cancel()

        errorMessage = nil

        parsingMethod = ""

        processingTask = Task {

            await parseExistingOCRText()
        }
    }

    private func processReceipt() async {

        guard let image else {

            return
        }

        isProcessing = true

        errorMessage = nil

        parsingMethod = "Reading receipt text..."

        defer {

            isProcessing = false
        }

        do {

            try Task.checkCancellation()

            let recognizedText =
                try await OCRService.recognizeText(
                    from: image
                )

            try Task.checkCancellation()

            let cleanedText =
                recognizedText.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

            guard !cleanedText.isEmpty else {

                throw ReceiptScannerError.noTextDetected
            }

            extractedText = cleanedText

            parsingMethod =
                "Analysing with Apple Intelligence..."

            receipt = try await parseReceipt(
                from: cleanedText
            )

            try Task.checkCancellation()

            parsingMethod =
                "Parsed with Apple Intelligence"

        } catch is CancellationError {

            parsingMethod = ""

        } catch {

            receipt = .empty

            parsingMethod = ""

            errorMessage =
                readableErrorMessage(for: error)
        }
    }

    private func parseExistingOCRText() async {

        let cleanedText =
            extractedText.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !cleanedText.isEmpty else {

            errorMessage =
                ReceiptScannerError
                .noTextDetected
                .localizedDescription

            return
        }

        isProcessing = true

        errorMessage = nil

        parsingMethod =
            "Analysing with Apple Intelligence..."

        defer {

            isProcessing = false
        }

        do {

            try Task.checkCancellation()

            receipt = try await parseReceipt(
                from: cleanedText
            )

            try Task.checkCancellation()

            parsingMethod =
                "Parsed with Apple Intelligence"

        } catch is CancellationError {

            parsingMethod = ""

        } catch {

            receipt = .empty

            parsingMethod = ""

            errorMessage =
                readableErrorMessage(for: error)
        }
    }

    private func parseReceipt(
        from text: String
    ) async throws -> ParsedReceipt {

        guard #available(
            iOS 26.0,
            macOS 26.0,
            *
        ) else {

            throw ReceiptScannerError
                .unsupportedOperatingSystem
        }

        let parser =
            AppleIntelligenceReceiptParser()

        guard parser.isAvailable else {

            throw ReceiptScannerError
                .appleIntelligenceUnavailable
        }

        let parsedReceipt =
            try await parser.parseReceipt(
                from: text
            )

        return sanitise(
            parsedReceipt,
            rawText: text
        )
    }

    private func sanitise(
        _ parsedReceipt: ParsedReceipt,
        rawText: String
    ) -> ParsedReceipt {

        var cleanedReceipt =
            parsedReceipt

        cleanedReceipt.merchant =
            cleanedReceipt.merchant
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        cleanedReceipt.title =
            cleanedReceipt.title
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        cleanedReceipt.date =
            cleanedReceipt.date
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        cleanedReceipt.category =
            normalisedCategory(
                cleanedReceipt.category
            )

        cleanedReceipt.items =
            cleanItems(
                cleanedReceipt.items
            )

        if let total = cleanedReceipt.total,
           total <= 0 {

            cleanedReceipt.total = nil
        }

        if let subtotal = cleanedReceipt.subtotal,
           subtotal <= 0 {

            cleanedReceipt.subtotal = nil
        }

        if let tax = cleanedReceipt.tax,
           tax < 0 {

            cleanedReceipt.tax = nil
        }

        cleanedReceipt.rawText =
            rawText

        return cleanedReceipt
    }

    private func cleanItems(
        _ items: [String]
    ) -> [String] {

        var encounteredItems: Set<String> = []

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

    private func normalisedCategory(
        _ category: String
    ) -> String {

        let cleanedCategory =
            category.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let allowedCategories = [
            "Food",
            "Groceries",
            "Transport",
            "Shopping",
            "Entertainment",
            "Healthcare",
            "Bills",
            "Other"
        ]

        if let matchingCategory =
            allowedCategories.first(
                where: {
                    $0.caseInsensitiveCompare(
                        cleanedCategory
                    ) == .orderedSame
                }
            ) {

            return matchingCategory
        }

        return "Other"
    }

    private func readableErrorMessage(
        for error: Error
    ) -> String {

        if let scannerError =
            error as? ReceiptScannerError {

            return scannerError
                .localizedDescription
        }

        let description =
            error.localizedDescription

        if description.localizedCaseInsensitiveContains(
            "exceededContextWindowSize"
        ) ||
        description.localizedCaseInsensitiveContains(
            "maximum allowed context size"
        ) {

            return """
            The receipt could not be analysed because one of the AI processing sections was still too large. Try scanning a clearer receipt or reducing unnecessary surrounding content.
            """
        }

        if description.localizedCaseInsensitiveContains(
            "guardrail"
        ) {

            return """
            Apple Intelligence could not process this receipt because the generated response was blocked by the model's safety checks.
            """
        }

        if description.localizedCaseInsensitiveContains(
            "assets"
        ) ||
        description.localizedCaseInsensitiveContains(
            "not ready"
        ) {

            return """
            Apple Intelligence is still preparing its on-device model. Check that Apple Intelligence is enabled and try again later.
            """
        }

        return """
        Apple Intelligence could not analyse this receipt: \(description)
        """
    }
}

enum ReceiptScannerError: LocalizedError {

    case noTextDetected

    case appleIntelligenceUnavailable

    case unsupportedOperatingSystem

    var errorDescription: String? {

        switch self {

        case .noTextDetected:

            return """
            No readable text was detected in the receipt.
            """

        case .appleIntelligenceUnavailable:

            return """
            Apple Intelligence is unavailable. Check that the device supports Apple Intelligence, it is enabled in Settings, and the required model has finished downloading.
            """

        case .unsupportedOperatingSystem:

            return """
            AI receipt parsing requires iOS 26 or macOS 26 or later.
            """
        }
    }
}
