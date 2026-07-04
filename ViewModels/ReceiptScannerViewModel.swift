//
//  ReceiptScannerViewModel.swift
//  Budgetting
//
//  Created by Zacharie on 4/7/26.
//

import Foundation
import Observation

@Observable
final class ReceiptScannerViewModel {

    var image: PlatformImage?

    var extractedText = ""

    var parsedReceipt = ParsedReceipt()

    var isProcessing = false

    private let ocrService = OCRService()

    private let parser = ReceiptParser()

    func setImage(_ image: PlatformImage) {

        self.image = image

        extractedText = ""

        parsedReceipt = ParsedReceipt()

    }

    @MainActor
    func scanReceipt() async {

        guard let image else {
            return
        }

        isProcessing = true

        do {

            extractedText = try await ocrService.recognizeText(from: image)

            parsedReceipt = parser.parse(text: extractedText)

        } catch {

            extractedText = error.localizedDescription

        }

        isProcessing = false

    }

}
