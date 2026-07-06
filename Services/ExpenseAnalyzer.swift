//
//  ExpenseAnalyzer.swift
//  Budgetting
//
//  Created by Zacharie on 6/7/26.
//

import Foundation

struct ExpenseSummary {
    let totalSpent: Double
    let transactionCount: Int
    let averageExpense: Double
    let topCategory: String
    let topMerchant: String
    let categoryBreakdown: [String: Double]
    let largestExpense: Double
    let smallestExpense: Double
    let uniqueMerchants: Int
    let uniqueCategories: Int
    let mostRecentMerchant: String
}

final class ExpenseAnalyzer {

    func analyze(expenses: [Expense]) -> ExpenseSummary {

        let totalSpent = expenses.reduce(0) {
            $0 + $1.amount
        }

        let averageExpense =
            expenses.isEmpty
            ? 0
            : totalSpent / Double(expenses.count)

        let merchantGroups = Dictionary(
            grouping: expenses,
            by: \.merchant
        )

        let categoryGroups = Dictionary(
            grouping: expenses,
            by: \.category
        )

        let topMerchant =
            merchantGroups.max {
                $0.value.count < $1.value.count
            }?.key ?? "-"

        let categoryBreakdown =
            categoryGroups.mapValues {

                $0.reduce(0) {
                    $0 + $1.amount
                }

            }

        let topCategory =
            categoryBreakdown.max {
                $0.value < $1.value
            }?.key ?? "-"

        let largestExpense =
            expenses.map(\.amount).max() ?? 0

        let smallestExpense =
            expenses.map(\.amount).min() ?? 0

        let uniqueMerchants =
            Set(expenses.map(\.merchant)).count

        let uniqueCategories =
            Set(expenses.map(\.category)).count

        let mostRecentMerchant =
            expenses
                .sorted { $0.date > $1.date }
                .first?
                .merchant ?? "-"

        return ExpenseSummary(

            totalSpent: totalSpent,

            transactionCount: expenses.count,

            averageExpense: averageExpense,

            topCategory: topCategory,

            topMerchant: topMerchant,

            categoryBreakdown: categoryBreakdown,

            largestExpense: largestExpense,

            smallestExpense: smallestExpense,

            uniqueMerchants: uniqueMerchants,

            uniqueCategories: uniqueCategories,

            mostRecentMerchant: mostRecentMerchant

        )

    }

}

