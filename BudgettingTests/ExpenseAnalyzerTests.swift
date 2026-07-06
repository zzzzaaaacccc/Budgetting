//
//  ExpenseAnalyzerTests.swift
//  Budgetting
//
//  Created by Zacharie on 6/7/26.
//

import Testing
@testable import Budgetting

struct ExpenseAnalyzerTests {

    @Test
    func calculatesSummaryCorrectly() {

        let analyzer = ExpenseAnalyzer()

        let expenses = [

            Expense(
                title: "Coffee",
                merchant: "Starbucks",
                amount: 5,
                category: "Food"
            ),

            Expense(
                title: "Lunch",
                merchant: "TPY Hawker",
                amount: 15,
                category: "Food"
            ),

            Expense(
                title: "Groceries",
                merchant: "NTUC",
                amount: 30,
                category: "Groceries"
            )

        ]

        let summary = analyzer.analyze(expenses: expenses)

        #expect(summary.totalSpent == 50)
        #expect(summary.transactionCount == 3)
        #expect(
            abs(summary.averageExpense - (50.0 / 3.0)) < 0.001
        )

    }

}
