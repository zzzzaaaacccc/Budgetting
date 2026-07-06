//
//  AppleIntelligenceExpenseAssistant.swift
//  Budgetting
//
//  Created by Zacharie on 6/7/26.
//

import Foundation
import FoundationModels

@available(macOS 26.0, iOS 26.0, *)
final class AppleIntelligenceExpenseAssistant {

    private let session = LanguageModelSession(
        instructions:
        """
        You are an intelligent personal finance assistant.

        Answer questions ONLY using the data provided.

        Rules:
        • Never invent expenses, items, prices, or merchants.
        • Never guess.
        • If the answer cannot be determined, say so.
        • Keep answers under 100 words.
        • Be concise and friendly.
        """
    )

    func answer(
        question: String,
        expenses: [Expense]
    ) async throws -> String {

        let expenseText = expenses.map {
            """
            Merchant: \($0.merchant)
            Title: \($0.title)
            Amount: SGD \(String(format: "%.2f", $0.amount))
            Category: \($0.category)
            Date: \($0.date.formatted(date: .abbreviated, time: .omitted))
            """
        }
        .joined(separator: "\n\n")

        let prompt =
        """
        Expense Database:

        \(expenseText)

        User Question:

        \(question)
        """

        let response = try await session.respond(to: prompt)

        return response.content
    }

    func answer(
        question: String,
        expense: Expense
    ) async throws -> String {

        let receiptItems = expense.receiptItems ?? []

        let items = receiptItems.isEmpty
            ? "No parsed items available."
            : receiptItems.joined(separator: "\n")

        let receiptText = expense.receiptText ?? ""

        let ocrText = receiptText.isEmpty
            ? "No OCR text available."
            : receiptText

        let prompt =
        """
        Single Receipt:

        Merchant:
        \(expense.merchant)

        Title:
        \(expense.title)

        Amount:
        SGD \(String(format: "%.2f", expense.amount))

        Category:
        \(expense.category)

        Date:
        \(expense.date.formatted(date: .abbreviated, time: .omitted))

        Parsed Items:
        \(items)

        OCR Text:
        \(ocrText)

        User Question:

        \(question)
        """

        let response = try await session.respond(to: prompt)

        return response.content
    }
}
