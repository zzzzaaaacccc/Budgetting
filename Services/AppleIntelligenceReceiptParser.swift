//
//  AppleIntelligenceReceiptParser.swift
//  Budgetting
//
//  Created by Zacharie on 6/7/26.
//

import Foundation
import FoundationModels

@available(macOS 26.0, iOS 26.0, *)
final class AppleIntelligenceReceiptParser {

    private let session = LanguageModelSession(
        instructions: """
        You are an expert accountant and receipt parser.

        The receipt text comes from OCR and may contain spelling mistakes,
        missing characters and formatting errors.

        Your job is to extract clean, structured information.

        Rules:

        • Correct obvious OCR mistakes when you are confident.
        • Never invent information.
        • Ignore receipt numbers, GST lines, cashier IDs, payment references,
          loyalty information, barcodes and random numbers.
        • Clean product names into readable English.
        • If only one product was purchased, use it as the expense title.
        • If multiple products were purchased, generate a meaningful title
          such as:
            - Grocery Shopping
            - Weekly Groceries
            - Lunch
            - Dinner
            - Coffee
            - Taxi Ride
            - Pharmacy Purchase
            - Shopping

        Merchant names should be normalized.

        Examples:

        SENG SKNG -> Sheng Siong
        NTUC FARPRCE -> NTUC FairPrice
        NCAFE -> Nescafé

        Categories MUST be exactly one of:

        Food
        Groceries
        Transport
        Shopping
        Entertainment
        Bills
        Healthcare
        Other

        Category rules:

        • Supermarkets are Groceries.
        • Restaurants, cafés and fast food are Food.
        • Grab, taxi, MRT and buses are Transport.
        • Pharmacies are Healthcare.
        • Shopping malls and retail stores are Shopping.

        Return only structured data.
        """
    )

    func parseReceipt(from ocrText: String) async throws -> ParsedReceipt {

        let response = try await session.respond(
            to:
            """
            Parse the following receipt.

            OCR Text:

            \(ocrText)
            """,
            generating: ParsedReceipt.self
        )

        return response.content
    }
}
