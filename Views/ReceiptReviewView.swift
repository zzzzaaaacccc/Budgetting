//
//  ReceiptReviewView.swift
//  Budgetting
//
//  Created by Zacharie on 4/7/26.
//

import SwiftUI
import SwiftData

struct ReceiptReviewView: View {

    @Environment(\.modelContext)
    private var modelContext

    @Environment(\.dismiss)
    private var dismiss

    @Binding var receipt: ParsedReceipt
    let receiptImage: Data?
    let receiptText: String

    @State private var showSaved = false

    var body: some View {

        VStack(alignment: .leading, spacing: 16) {

            Text("Receipt Summary")
                .font(.title2)
                .bold()

            TextField("Merchant", text: $receipt.merchant)
                .textFieldStyle(.roundedBorder)

            TextField("Title", text: $receipt.title)
                .textFieldStyle(.roundedBorder)

            TextField(
                "Amount",
                value: $receipt.total,
                format: .number
            )
            .textFieldStyle(.roundedBorder)

            LabeledContent("Date") {

                Text(
                    receipt.date.isEmpty
                    ? "-"
                    : receipt.date
                )

            }

            Picker("Category", selection: $receipt.category) {

                Text("Food").tag("Food")
                Text("Groceries").tag("Groceries")
                Text("Transport").tag("Transport")
                Text("Shopping").tag("Shopping")
                Text("Entertainment").tag("Entertainment")
                Text("Healthcare").tag("Healthcare")
                Text("Bills").tag("Bills")
                Text("Other").tag("Other")

            }
            .pickerStyle(.menu)

            if !receipt.items.isEmpty {

                Divider()

                Text("Items")
                    .font(.headline)

                ScrollView {

                    VStack(alignment: .leading, spacing: 6) {

                        ForEach(Array(receipt.items.enumerated()), id: \.offset) { _, item in

                            Text("• \(item)")
                                .frame(maxWidth: .infinity, alignment: .leading)

                        }

                    }

                }
                .frame(maxHeight: 180)

            }

            Divider()

            Button {

                saveExpense()

            } label: {

                Label("Save Expense", systemImage: "square.and.arrow.down.fill")
                    .frame(maxWidth: .infinity)

            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

        }
        .padding()
        .alert("Expense Saved", isPresented: $showSaved) {

            Button("OK") {

                dismiss()

            }

        } message: {

            Text("Your expense has been added successfully.")

        }

    }

    private func saveExpense() {

        guard let amount = receipt.total else {
            return
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"

        let expenseDate = formatter.date(from: receipt.date) ?? Date()

        let expense = Expense(
            title: receipt.title.isEmpty ? receipt.merchant : receipt.title,
            merchant: receipt.merchant,
            amount: amount,
            category: receipt.category,
            date: expenseDate,
            receiptImage: receiptImage,
            receiptText: receiptText,
            receiptItems: receipt.items
        )

        modelContext.insert(expense)

        do {

            try modelContext.save()

            showSaved = true

        } catch {

            print(error)

        }

    }

}

#Preview {
    ReceiptReviewView(
        receipt: .constant(
            ParsedReceipt(
                merchant: "Starbucks",
                title: "Coffee",
                total: 8.60,
                date: "04/07/2026",
                category: "Food",
                items: [
                    "Latte",
                    "Blueberry Muffin"
                ]
            )
        ),
        receiptImage: nil,
        receiptText: "Sample OCR text"
    )
    .modelContainer(for: Expense.self, inMemory: true)
}
