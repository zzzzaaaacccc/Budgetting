//
//  AddExpenseView.swift
//  Budgetting
//
//  Created by Zacharie on 4/7/26.
//
import SwiftUI
import SwiftData

struct AddExpenseView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var merchant = ""
    @State private var amount = ""
    @State private var category = "Dining"

    let categories = [
        "Dining",
        "Groceries",
        "Shopping",
        "Transport",
        "Entertainment",
        "Bills",
        "Others"
    ]

    var body: some View {

        NavigationStack {

            Form {

                Section("Expense Details") {

                    TextField("Title", text: $title)

                    TextField("Merchant", text: $merchant)

                    TextField("Amount", text: $amount)

                }

                Section("Category") {

                    Picker("Category", selection: $category) {

                        ForEach(categories, id: \.self) { category in
                            Text(category)
                        }

                    }

                }

            }
            .navigationTitle("New Expense")

            .toolbar {

                ToolbarItem(placement: .cancellationAction) {

                    Button("Cancel") {
                        dismiss()
                    }

                }

                ToolbarItem(placement: .confirmationAction) {

                    Button("Save") {
                        saveExpense()
                    }
                    .disabled(title.isEmpty || amount.isEmpty)

                }

            }

        }

    }

    private func saveExpense() {

        guard let value = Double(amount) else {
            return
        }

        let expense = Expense(
            title: title,
            merchant: merchant,
            amount: value,
            category: category
        )

        modelContext.insert(expense)

        dismiss()

    }

}

#Preview {
    AddExpenseView()
        .modelContainer(for: Expense.self, inMemory: true)
}
