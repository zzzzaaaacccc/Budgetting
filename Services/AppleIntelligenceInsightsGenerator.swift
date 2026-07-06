//
//  AppleIntelligenceInsightsGenerator.swift
//  Budgetting
//
//  Created by Zacharie on 6/7/26.
//

import Foundation
import FoundationModels

@available(macOS 26.0, iOS 26.0, *)
final class AppleIntelligenceInsightsGenerator {

    private let session = LanguageModelSession(
        instructions:
        """
        You are Apple's on-device personal finance assistant.

        Your job is to explain spending behaviour, not give generic financial advice.

        Rules:

        • Use only the provided data.
        • Never invent numbers.
        • Never tell the user to "track spending" or "collect more data".
        • Do not mention missing information unless there are fewer than 3 expenses.
        • Write naturally and professionally.
        • Keep the response between 3 and 5 bullet points.
        • Highlight interesting patterns rather than obvious facts.
        • Mention merchants, categories and spending behaviour.
        • Do not repeat statistics already shown elsewhere in the UI.
        • Be concise.
        """
    )

    func generateInsights(
        from summary: ExpenseSummary
    ) async throws -> String {

        let breakdown = summary.categoryBreakdown
            .sorted { $0.value > $1.value }
            .map {
                "\($0.key): SGD \(String(format: "%.2f", $0.value))"
            }
            .joined(separator: "\n")

        var prompt =
        """
        Analyse the following spending summary.

        Total spent:
        SGD \(String(format: "%.2f", summary.totalSpent))

        Number of transactions:
        \(summary.transactionCount)

        Average expense:
        SGD \(String(format: "%.2f", summary.averageExpense))

        Most frequent merchant:
        \(summary.topMerchant)

        Largest spending category:
        \(summary.topCategory)

        Category breakdown:

        \(breakdown)
        """

        if summary.transactionCount < 5 {

            prompt +=
            """

            There are only a few transactions.

            Do not discuss long-term trends.

            Do not make assumptions about future behaviour.

            Focus only on observations that can be directly supported by the available transactions.
            """

        }

        prompt +=
        """

        Produce between 3 and 5 bullet points.

        Avoid repeating the statistics already displayed in the interface.

        Examples of good insights:

        • Groceries make up most of your spending.
        • TPY Hawker is your most frequently visited merchant.
        • Your purchases are generally small and consistent.
        • No unusually large expenses were detected.
        • Spending is concentrated in one category.

        Avoid generic advice like:
        • Track your spending.
        • Collect more data.
        • Build better habits.
        • You should budget better.

        Only describe observations that are supported by the supplied data.
        """

        let response = try await session.respond(
            to: prompt
        )

        return response.content
    }
}
