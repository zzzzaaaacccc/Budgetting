//
//  OCRService.swift
//  Budgetting
//
//  Created by Zacharie on 4/7/26.
//

import Foundation
import Vision

#if os(iOS)
import UIKit
public typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
public typealias PlatformImage = NSImage
#endif

final class OCRService {

    func recognizeText(from image: PlatformImage) async throws -> String {

#if os(iOS)

        guard let cgImage = image.cgImage else {
            return ""
        }

#else

        guard
            let data = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: data),
            let cgImage = bitmap.cgImage
        else {
            return ""
        }

#endif

        return try await withCheckedThrowingContinuation { continuation in

            let request = VNRecognizeTextRequest { request, error in

                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }

                let text = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")

                continuation.resume(returning: text)

            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage)

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }

        }

    }

}
