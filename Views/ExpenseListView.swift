//
//  ExpenseListView.swift
//  Budgetting
//
//  Created by Zacharie on 4/7/26.
//

import SwiftUI
import SwiftData

struct ExpenseListView: View {

    @Environment(\.modelContext)
    private var modelContext

    @Query(sort: \Expense.date, order: .reverse)
    private var expenses: [Expense]

    var body: some View {

        List {

            ForEach(expenses) { expense in

                NavigationLink {

                    VStack(alignment: .leading, spacing: 12) {

                        Text(expense.title)
                            .font(.title)

                        Text(expense.merchant)

                        Text(expense.category)

                        Text("$\(expense.amount, specifier: "%.2f")")

                    }
                    .padding()

                } label: {

                    ExpenseRowView(expense: expense)

                }

            }
            .onDelete(perform: deleteExpenses)

        }

    }

    private func deleteExpenses(offsets: IndexSet) {

        withAnimation {

            for index in offsets {

                modelContext.delete(expenses[index])

            }

        }

    }

}

#Preview {
    ExpenseListView()
        .modelContainer(for: Expense.self, inMemory: true)
}
