//
//  ReceiptScannerViewModel.swift
//  Budgetting
//
//  Created by Zacharie on 4/7/26.
//

import Foundation
import Observation

#if os(macOS)
import AppKit
#else
import UIKit
#endif

@available(macOS 26.0, iOS 26.0, *)
@Observable
final class ReceiptScannerViewModel {

    var image: PlatformImage?

    var imageData: Data? {

        guard let image else {
            return nil
        }

        #if os(macOS)

        guard
            let tiffData = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData),
            let pngData = bitmap.representation(
                using: .png,
                properties: [:]
            )
        else {
            return nil
        }

        return pngData

        #else

        return image.pngData()

        #endif

    }

    var extractedText = ""

    var parsedReceipt = ParsedReceipt()

    var isProcessing = false

    private let ocrService = OCRService()

    private let parser = ReceiptParser()

    @available(macOS 26.0, iOS 26.0, *)
    private let aiParser = AppleIntelligenceReceiptParser()

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

        defer {
            isProcessing = false
        }

        do {

            extractedText = try await ocrService.recognizeText(from: image)

            if #available(macOS 26.0, iOS 26.0, *) {

                do {

                    parsedReceipt = try await aiParser.parseReceipt(
                        from: extractedText
                    )

                    print("✅ Parsed using Apple Intelligence")

                    return

                } catch {

                    print("⚠️ Apple Intelligence failed.")

                    print(error)

                }

            }

            parsedReceipt = parser.parse(text: extractedText)

            print("✅ Parsed using rule-based parser")

        } catch {

            extractedText = error.localizedDescription

        }

    }

}
