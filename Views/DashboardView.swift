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

    private var totalSpent: Double {
        viewModel.totalSpent(from: expenses)
    }

    private var remainingBudget: Double {
        viewModel.remainingBudget(from: expenses)
    }

    private var progress: Double {
        viewModel.spendingProgress(from: expenses)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                header

                budgetHeroCard

                statsGrid

                SpendingChartView(expenses: expenses)

                recentExpenses
            }
            .padding()
        }
        .navigationTitle("Dashboard")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(greeting)
                .font(.largeTitle)
                .bold()

            Text("Here’s your spending summary.")
                .foregroundStyle(.secondary)
        }
    }

    private var budgetHeroCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Budget Remaining")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text(remainingBudget, format: .currency(code: "SGD"))
                        .font(.system(size: 40, weight: .bold))
                }

                Spacer()

                BudgetRingView(
                    progress: progress,
                    amountRemaining: remainingBudget
                )
            }

            VStack(alignment: .leading, spacing: 12) {

                ProgressView(
                    value: totalSpent,
                    total: viewModel.monthlyBudget
                )

                HStack {

                    Text("Spent")

                    Spacer()

                    Text(
                        totalSpent,
                        format: .currency(code: "SGD")
                    )

                }
                .font(.caption)

                HStack {

                    Text("Budget")

                    Spacer()

                    Text(
                        viewModel.monthlyBudget,
                        format: .currency(code: "SGD")
                    )

                }
                .font(.caption)

            }

        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var statsGrid: some View {

        LazyVGrid(
            columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ],
            spacing: 16
        ) {

            DashboardCard(
                title: "Spent",
                systemImage: "creditcard.fill"
            ) {

                Text(totalSpent,
                     format: .currency(code: "SGD"))
                    .font(.title.bold())

            }

            DashboardCard(
                title: "Transactions",
                systemImage: "list.bullet.rectangle"
            ) {

                Text("\(expenses.count)")
                    .font(.title.bold())

            }

            DashboardCard(
                title: "Top Category",
                systemImage: "chart.pie.fill"
            ) {

                Text(topCategory)
                    .font(.title3.bold())

            }

            DashboardCard(
                title: "Largest Expense",
                systemImage: "arrow.up.circle.fill"
            ) {

                Text(
                    largestExpense,
                    format: .currency(code: "SGD")
                )
                .font(.title3.bold())

            }

        }

    }

    
    private var recentExpenses: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Expenses")
                .font(.title2)
                .bold()

            if expenses.isEmpty {
                ContentUnavailableView(
                    "No Expenses Yet",
                    systemImage: "tray",
                    description: Text("Scan your first receipt to begin tracking.")
                )
            } else {
                ForEach(expenses.prefix(5)) { expense in
                    ExpenseRowView(expense: expense)
                }
            }
        }
    }

    private var topCategory: String {
        let grouped = Dictionary(grouping: expenses, by: \.category)
        let totals = grouped.mapValues { $0.reduce(0) { $0 + $1.amount } }

        return totals.max { $0.value < $1.value }?.key ?? "-"
    }

    private var largestExpense: Double {
        expenses.map(\.amount).max() ?? 0
    }
    
    private var greeting: String {

        let hour = Calendar.current.component(
            .hour,
            from: .now
        )

        switch hour {

        case 5..<12:
            return "Good Morning ☀️"

        case 12..<18:
            return "Good Afternoon 🌤"

        default:
            return "Good Evening 🌙"

        }

    }
}

#Preview {
    DashboardView()
        .modelContainer(for: Expense.self, inMemory: true)
}
