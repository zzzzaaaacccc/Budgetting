//
//  DashboardView.swift
//  Budgetting
//
//  Created by Zacharie on 4/7/26.
//

import SwiftUI
import SwiftData

struct DashboardView: View {

    @Query(sort: \Expense.date, order: .reverse)
    private var expenses: [Expense]

    private let monthlyBudget: Double = 1000

    private var totalSpent: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    private var remainingBudget: Double {
        max(monthlyBudget - totalSpent, 0)
    }

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 24) {

                Text("Budgetting")
                    .font(.largeTitle)
                    .bold()

                BudgetCardView(
                    monthlyBudget: monthlyBudget,
                    totalSpent: totalSpent
                )

                recentExpenses

            }
            .padding()

        }
        .navigationTitle("Dashboard")

    }


    private var recentExpenses: some View {

        VStack(alignment: .leading, spacing: 12) {

            Text("Recent Expenses")
                .font(.headline)

            if expenses.isEmpty {

                ContentUnavailableView(
                    "No Expenses Yet",
                    systemImage: "tray"
                )

            } else {

                ForEach(expenses.prefix(5)) { expense in

                    ExpenseRowView(expense: expense)

                    Divider()

                }

            }

        }

    }

}

#Preview {
    DashboardView()
        .modelContainer(for: Expense.self, inMemory: true)
}
