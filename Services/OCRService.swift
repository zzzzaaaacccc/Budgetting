//
//  OCRService.swift
//  Budgetting
//
//  Created by Zacharie on 4/7/26.
//

import CoreGraphics
import Foundation
@preconcurrency import Vision

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

enum OCRService {

    static func recognizeText(
        from image: PlatformImage
    ) async throws -> String {

        let cgImage = try createCGImage(from: image)

        return try await withCheckedThrowingContinuation { continuation in

            let request = VNRecognizeTextRequest { request, error in

                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations =
                        request.results as? [VNRecognizedTextObservation]
                else {
                    continuation.resume(returning: "")
                    return
                }

                let text = observations
                    .compactMap {
                        $0.topCandidates(1).first?.string
                    }
                    .joined(separator: "\n")

                continuation.resume(returning: text)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = [
                "en-SG",
                "en-US"
            ]

            let handler = VNImageRequestHandler(
                cgImage: cgImage,
                options: [:]
            )

            DispatchQueue.global(
                qos: .userInitiated
            ).async {

                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private static func createCGImage(
        from image: PlatformImage
    ) throws -> CGImage {

#if os(iOS)
        guard let cgImage = image.cgImage else {
            throw OCRServiceError.invalidImage
        }

        return cgImage
#elseif os(macOS)
        var proposedRect = CGRect(
            origin: .zero,
            size: image.size
        )

        guard let cgImage = image.cgImage(
            forProposedRect: &proposedRect,
            context: nil,
            hints: nil
        ) else {
            throw OCRServiceError.invalidImage
        }

        return cgImage
#endif
    }
}

enum OCRServiceError: LocalizedError {

    case invalidImage

    var errorDescription: String? {

        switch self {
        case .invalidImage:
            return "The selected file could not be converted into an image."
        }
    }
}
