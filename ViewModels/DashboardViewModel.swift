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

    let monthlyBudget: Double = 1000

    func totalSpent(from expenses: [Expense]) -> Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    func remainingBudget(from expenses: [Expense]) -> Double {
        max(monthlyBudget - totalSpent(from: expenses), 0)
    }

}
