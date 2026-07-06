//
//  DashboardViewModelTests.swift
//  Budgetting
//
//  Created by Zacharie on 6/7/26.
//

import Testing
@testable import Budgetting

struct DashboardViewModelTests {

    @Test
    func totalSpentCalculation() {

        let vm = DashboardViewModel()

        let expenses = [
            Expense(
                title: "Coffee",
                merchant: "Starbucks",
                amount: 6.50,
                category: "Food"
            ),
            Expense(
                title: "Groceries",
                merchant: "NTUC",
                amount: 23.50,
                category: "Groceries"
            )
        ]

        #expect(
            vm.totalSpent(from: expenses) == 30.0
        )

    }

    @Test
    func remainingBudgetCalculation() {

        let vm = DashboardViewModel()

        vm.monthlyBudget = 100

        let expenses = [

            Expense(
                title: "Lunch",
                merchant: "TPY Hawker",
                amount: 20,
                category: "Food"
            )

        ]

        #expect(
            vm.remainingBudget(from: expenses) == 80
        )

    }

}
