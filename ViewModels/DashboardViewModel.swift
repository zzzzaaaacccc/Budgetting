//
//  DashboardViewModel.swift
//  Budgetting
//
//  Created by Zacharie on 4/7/26.
//

import Foundation
import Observation

@Observable
final class DashboardViewModel {

    var monthlyBudget: Double = 1000

    func totalSpent(from expenses: [Expense]) -> Double {
        expenses.reduce(0) { total, expense in
            total + expense.amount
        }
    }

    func remainingBudget(from expenses: [Expense]) -> Double {
        monthlyBudget - totalSpent(from: expenses)
    }

    func spendingProgress(from expenses: [Expense]) -> Double {
        guard monthlyBudget > 0 else {
            return 0
        }

        return min(totalSpent(from: expenses) / monthlyBudget, 1.0)
    }

}
