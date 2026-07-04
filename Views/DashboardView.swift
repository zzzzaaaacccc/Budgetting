//
//  DashboardView.swift
//  Budgetting
//
//  Created by Zacharie on 4/7/26.
//

import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {

    @Query(sort: \Expense.date, order: .reverse)
    private var expenses: [Expense]
    
    @State private var viewModel = DashboardViewModel()


    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 24) {

                Text("Budgetting")
                    .font(.largeTitle)
                    .bold()

                BudgetCardView(
                    monthlyBudget: viewModel.monthlyBudget,
                    totalSpent: viewModel.totalSpent(from: expenses)
                )

                SpendingChartView(expenses: expenses)
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
