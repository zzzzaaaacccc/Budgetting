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

    @State private var searchText = ""
    @State private var selectedCategory = "All"

    @State private var selectedExpense: Expense?

    private let categories = [
        "All",
        "Food",
        "Groceries",
        "Transport",
        "Shopping",
        "Entertainment",
        "Bills",
        "Health",
        "Education",
        "Other"
    ]

    private var filteredExpenses: [Expense] {

        expenses.filter { expense in

            let matchesSearch =
                searchText.isEmpty ||
                expense.title.localizedCaseInsensitiveContains(searchText) ||
                expense.merchant.localizedCaseInsensitiveContains(searchText)

            let matchesCategory =
                selectedCategory == "All" ||
                expense.category == selectedCategory

            return matchesSearch && matchesCategory

        }

    }

    var body: some View {

        VStack {

            Picker("Category", selection: $selectedCategory) {

                ForEach(categories, id: \.self) { category in

                    Text(category)

                }

            }
            .pickerStyle(.menu)
            .padding(.horizontal)

            List {

                ForEach(filteredExpenses) { expense in

                    Button {

                        selectedExpense = expense

                    } label: {

                        ExpenseRowView(expense: expense)

                    }
                    .buttonStyle(.plain)

                }
                .onDelete(perform: deleteExpenses)

            }
            .searchable(text: $searchText)

        }
        .navigationTitle("Expenses")
        .sheet(item: $selectedExpense) { expense in

            EditExpenseView(expense: expense)

        }

    }

    private func deleteExpenses(offsets: IndexSet) {

        withAnimation {

            for index in offsets {

                let expense = filteredExpenses[index]
                modelContext.delete(expense)

            }

        }

    }

}

#Preview {

    ExpenseListView()
        .modelContainer(for: Expense.self, inMemory: true)

}
