//
//  EditExpenseView.swift
//  Budgetting
//
//  Created by Zacharie on 4/7/26.
//

import SwiftUI
import SwiftData

struct EditExpenseView: View {

    @Environment(\.dismiss) private var dismiss

    let expense: Expense

    @State private var title: String
    @State private var merchant: String
    @State private var amount: String
    @State private var category: String

    private let categories = [
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

    init(expense: Expense) {

        self.expense = expense

        _title = State(initialValue: expense.title)
        _merchant = State(initialValue: expense.merchant)
        _amount = State(initialValue: String(expense.amount))
        _category = State(initialValue: expense.category)

    }

    var body: some View {

        NavigationStack {

            Form {

                Section("Expense") {

                    TextField("Title", text: $title)

                    TextField("Merchant", text: $merchant)

                    TextField("Amount", text: $amount)
#if os(iOS)
                        .keyboardType(.decimalPad)
#endif

                    Picker("Category", selection: $category) {

                        ForEach(categories, id: \.self) { category in
                            Text(category)
                        }

                    }

                }

            }
            .navigationTitle("Edit Expense")
            .toolbar {

                ToolbarItem(placement: .confirmationAction) {

                    Button("Save") {

                        expense.title = title
                        expense.merchant = merchant
                        expense.amount = Double(amount) ?? 0
                        expense.category = category

                        dismiss()

                    }

                }

                ToolbarItem(placement: .cancellationAction) {

                    Button("Cancel") {

                        dismiss()

                    }

                }

            }

        }

    }

}

#Preview {

    EditExpenseView(
        expense: Expense(
            title: "Coffee",
            merchant: "Starbucks",
            amount: 6.50,
            category: "Food"
        )
    )

}
