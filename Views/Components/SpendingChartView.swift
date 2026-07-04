//
//  SpendingChartView.swift
//  Budgetting
//
//  Created by Zacharie on 4/7/26.
//

import SwiftUI
import Charts

struct SpendingChartView: View {

    let expenses: [Expense]

    private var groupedExpenses: [(String, Double)] {

        Dictionary(grouping: expenses) { $0.category }
            .map { (category, expenses) in
                (
                    category,
                    expenses.reduce(0) { $0 + $1.amount }
                )
            }
            .sorted { $0.1 > $1.1 }

    }

    var body: some View {

        VStack(alignment: .leading) {

            Text("Spending by Category")
                .font(.headline)

            Chart(groupedExpenses, id: \.0) { item in

                BarMark(
                    x: .value("Category", item.0),
                    y: .value("Amount", item.1)
                )

            }
            .frame(height: 250)

        }

    }

}

#Preview {

    SpendingChartView(expenses: [])

}
