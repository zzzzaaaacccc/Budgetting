//
//  InsightsView.swift
//  Budgetting
//
//  Created by Zacharie on 6/7/26.
//

import SwiftUI
import SwiftData

struct InsightsView: View {

    @Query(sort: \Expense.date, order: .reverse)
    private var expenses: [Expense]

    @State private var aiInsights = "Loading..."
    @State private var isLoading = false

    private let analyzer = ExpenseAnalyzer()

    var body: some View {
        let summary = analyzer.analyze(expenses: expenses)

        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                quickStats(summary)

                aiCard

                categoryBreakdown(summary)
            }
            .padding()
        }
        .navigationTitle("Insights")
        .task(id: expenses.count) {
            await generateInsights()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Spending Insights")
                .font(.largeTitle)
                .bold()

            Text("Powered by Apple Intelligence")
                .foregroundStyle(.secondary)
        }
    }

    private func quickStats(_ summary: ExpenseSummary) -> some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ],
            spacing: 16
        ) {
            DashboardCard(title: "Total Spent", systemImage: "creditcard.fill") {
                Text(summary.totalSpent, format: .currency(code: "SGD"))
                    .font(.title3.bold())
            }

            DashboardCard(title: "Average", systemImage: "divide.circle.fill") {
                Text(summary.averageExpense, format: .currency(code: "SGD"))
                    .font(.title3.bold())
            }

            DashboardCard(title: "Top Merchant", systemImage: "building.2.fill") {
                Text(summary.topMerchant)
                    .font(.title3.bold())
                    .lineLimit(1)
            }

            DashboardCard(title: "Top Category", systemImage: "chart.pie.fill") {
                Text(summary.topCategory)
                    .font(.title3.bold())
                    .lineLimit(1)
            }
        }
    }

    private var aiCard: some View {
        DashboardCard(title: "Apple Intelligence", systemImage: "sparkles") {
            if isLoading {
                HStack(spacing: 12) {
                    ProgressView()

                    Text("Generating insights...")
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(aiInsights)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func categoryBreakdown(_ summary: ExpenseSummary) -> some View {
        DashboardCard(title: "Category Breakdown", systemImage: "list.bullet") {
            if summary.categoryBreakdown.isEmpty {
                Text("No spending data yet.")
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 12) {
                    ForEach(
                        summary.categoryBreakdown
                            .sorted { $0.value > $1.value },
                        id: \.key
                    ) { category, amount in
                        HStack {
                            Text(category)

                            Spacer()

                            Text(amount, format: .currency(code: "SGD"))
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
        }
    }

    @MainActor
    private func generateInsights() async {
        guard #available(macOS 26.0, iOS 26.0, *) else {
            aiInsights = "Apple Intelligence is unavailable."
            return
        }

        guard !expenses.isEmpty else {
            aiInsights = "Add some expenses to generate insights."
            return
        }

        isLoading = true

        let summary = analyzer.analyze(expenses: expenses)

        do {
            let generator = AppleIntelligenceInsightsGenerator()

            aiInsights = try await generator.generateInsights(
                from: summary
            )
        } catch {
            aiInsights = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    InsightsView()
        .modelContainer(for: Expense.self, inMemory: true)
}
