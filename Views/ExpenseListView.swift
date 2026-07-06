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

            Picker(
                "Category",
                selection: $selectedCategory
            ) {

                ForEach(categories, id: \.self) { category in

                    Text(category)
                        .tag(category)

                }

            }
            .pickerStyle(.menu)
            .padding(.horizontal)

            List {

                ForEach(filteredExpenses) { expense in

                    NavigationLink {

                        ExpenseDetailView(
                            expense: expense
                        )

                    } label: {

                        ExpenseRowView(
                            expense: expense
                        )

                    }
                    .swipeActions {

                        Button(
                            role: .destructive
                        ) {

                            withAnimation {

                                modelContext.delete(expense)

                            }

                        } label: {

                            Label(
                                "Delete",
                                systemImage: "trash"
                            )

                        }

                    }

                }
                .onDelete(
                    perform: deleteExpenses
                )

            }
            .searchable(text: $searchText)

        }
        .navigationTitle("Expenses")

    }

    private func deleteExpenses(
        offsets: IndexSet
    ) {

        withAnimation {

            for index in offsets {

                modelContext.delete(
                    filteredExpenses[index]
                )

            }

        }

    }

}

#Preview {

    ExpenseListView()
        .modelContainer(
            for: Expense.self,
            inMemory: true
        )

}
