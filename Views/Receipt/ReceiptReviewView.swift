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
    @State private var errorMessage: String?

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(alignment: .leading, spacing: 20) {

                    receiptSummarySection
                    itemsSection
                    rawTextSection
                    saveButton
                }
                .padding()
            }
            .navigationTitle("Review Receipt")
            .toolbar {

                ToolbarItem(
                    placement: .cancellationAction
                ) {

                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert(
                "Expense Saved",
                isPresented: $showSaved
            ) {

                Button("OK") {
                    dismiss()
                }

            } message: {

                Text(
                    "Your expense has been added successfully."
                )
            }
            .alert(
                "Unable to Save Expense",
                isPresented: Binding(
                    get: {
                        errorMessage != nil
                    },
                    set: { isPresented in

                        if !isPresented {
                            errorMessage = nil
                        }
                    }
                )
            ) {

                Button("OK", role: .cancel) {
                    errorMessage = nil
                }

            } message: {

                Text(
                    errorMessage ??
                    "An unknown error occurred."
                )
            }
        }
    }

    private var receiptSummarySection: some View {

        VStack(alignment: .leading, spacing: 16) {

            Text("Receipt Summary")
                .font(.title2)
                .fontWeight(.semibold)

            TextField(
                "Merchant",
                text: $receipt.merchant
            )
            .textFieldStyle(.roundedBorder)

            TextField(
                "Title",
                text: $receipt.title
            )
            .textFieldStyle(.roundedBorder)

            TextField(
                "Amount",
                value: $receipt.total,
                format: .number.precision(
                    .fractionLength(2)
                )
            )
            .textFieldStyle(.roundedBorder)

            TextField(
                "Date",
                text: $receipt.date,
                prompt: Text("dd/MM/yyyy")
            )
            .textFieldStyle(.roundedBorder)

            if let subtotal = receipt.subtotal {

                LabeledContent(
                    "Subtotal",
                    value: subtotal.formatted(
                        .currency(code: "SGD")
                    )
                )
            }

            if let tax = receipt.tax {

                LabeledContent(
                    "Tax",
                    value: tax.formatted(
                        .currency(code: "SGD")
                    )
                )
            }

            Picker(
                "Category",
                selection: $receipt.category
            ) {

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
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(
            RoundedRectangle(cornerRadius: 16)
        )
    }

    @ViewBuilder
    private var itemsSection: some View {

        if !receipt.items.isEmpty {

            VStack(alignment: .leading, spacing: 12) {

                Text("Items")
                    .font(.headline)

                ForEach(
                    Array(receipt.items.enumerated()),
                    id: \.offset
                ) { index, item in

                    HStack {

                        TextField(
                            "Item",
                            text: Binding(
                                get: {
                                    receipt.items[index]
                                },
                                set: {
                                    receipt.items[index] = $0
                                }
                            )
                        )
                        .textFieldStyle(.roundedBorder)

                        Button(role: .destructive) {

                            receipt.items.remove(
                                at: index
                            )

                        } label: {

                            Image(
                                systemName: "trash"
                            )
                        }
                        .buttonStyle(.borderless)
                    }
                }

                Button {

                    receipt.items.append("")

                } label: {

                    Label(
                        "Add Item",
                        systemImage: "plus"
                    )
                }
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(
                RoundedRectangle(cornerRadius: 16)
            )
        }
    }

    private var rawTextSection: some View {

        DisclosureGroup("View OCR Text") {

            Text(
                receipt.rawText.isEmpty
                ? receiptText
                : receipt.rawText
            )
            .font(
                .system(
                    .caption,
                    design: .monospaced
                )
            )
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .textSelection(.enabled)
            .padding(.top)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(
            RoundedRectangle(cornerRadius: 16)
        )
    }

    private var saveButton: some View {

        Button {

            saveExpense()

        } label: {

            Label(
                "Save Expense",
                systemImage: "square.and.arrow.down.fill"
            )
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(!canSave)
    }

    private var canSave: Bool {

        guard let total = receipt.total else {
            return false
        }

        let merchant = receipt.merchant
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return !merchant.isEmpty && total > 0
    }

    private func saveExpense() {

        guard let amount = receipt.total,
              amount > 0
        else {

            errorMessage =
                "Please enter a valid receipt amount."

            return
        }

        let merchant = receipt.merchant
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !merchant.isEmpty else {

            errorMessage =
                "Please enter a merchant name."

            return
        }

        let expenseDate =
            parseDate(receipt.date) ?? Date()

        let savedTitle = receipt.title
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let savedReceiptText =
            receipt.rawText.isEmpty
            ? receiptText
            : receipt.rawText

        let cleanedItems = receipt.items
            .map {
                $0.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            }
            .filter {
                !$0.isEmpty
            }

        let expense = Expense(
            title: savedTitle.isEmpty
                ? merchant
                : savedTitle,
            merchant: merchant,
            amount: amount,
            category: receipt.category,
            date: expenseDate,
            receiptImage: receiptImage,
            receiptText: savedReceiptText,
            receiptItems: cleanedItems
        )

        modelContext.insert(expense)

        do {

            try modelContext.save()
            showSaved = true

        } catch {

            errorMessage =
                "The expense could not be saved: \(error.localizedDescription)"
        }
    }

    private func parseDate(
        _ dateString: String
    ) -> Date? {

        let cleanedDate = dateString
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !cleanedDate.isEmpty else {
            return nil
        }

        let formats = [
            "dd/MM/yyyy",
            "d/M/yyyy",
            "dd/MM/yy",
            "d/M/yy",
            "yyyy-MM-dd",
            "dd-MM-yyyy",
            "d-M-yyyy",
            "d MMM yyyy",
            "dd MMM yyyy",
            "d MMMM yyyy",
            "dd MMMM yyyy"
        ]

        for format in formats {

            let formatter = DateFormatter()

            formatter.locale = Locale(
                identifier: "en_SG"
            )

            formatter.dateFormat = format
            formatter.isLenient = false

            if let date = formatter.date(
                from: cleanedDate
            ) {
                return date
            }
        }

        return nil
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
                ],
                subtotal: 7.89,
                tax: 0.71,
                rawText: "Sample OCR text"
            )
        ),
        receiptImage: nil,
        receiptText: "Sample OCR text"
    )
    .modelContainer(
        for: Expense.self,
        inMemory: true
    )
}
