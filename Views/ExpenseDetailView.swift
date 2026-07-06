//
//  ExpenseDetailView.swift
//  Budgetting
//
//  Created by Zacharie on 4/7/26.
//

import SwiftUI
import SwiftData

#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct ExpenseDetailView: View {

    @Environment(\.modelContext)
    private var modelContext

    @Environment(\.dismiss)
    private var dismiss

    let expense: Expense

    @State private var question = ""
    @State private var answer = ""
    @State private var isAsking = false

    @State private var showEdit = false

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 24) {

                receiptImage

                detailsCard
                
                MerchantInfoView(merchant: expense.merchant)

                itemsCard

                askAICard

                actionButtons

            }
            .padding()

        }
        .navigationTitle(expense.title)
        .sheet(isPresented: $showEdit) {

            EditExpenseView(expense: expense)

        }

    }

    @ViewBuilder
    private var receiptImage: some View {

        if let data = expense.receiptImage {

#if os(macOS)

            if let image = NSImage(data: data) {

                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 20))

            }

#else

            if let image = UIImage(data: data) {

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 20))

            }

#endif

        }

    }

    private var detailsCard: some View {

        DashboardCard(
            title: "Expense Details",
            systemImage: "receipt.fill"
        ) {

            VStack(spacing: 12) {

                detailRow("Merchant", expense.merchant)

                detailRow(
                    "Amount",
                    expense.amount.formatted(.currency(code: "SGD"))
                )

                detailRow(
                    "Category",
                    expense.category
                )

                detailRow(
                    "Date",
                    expense.date.formatted(
                        date: .abbreviated,
                        time: .omitted
                    )
                )

            }

        }

    }

    private var itemsCard: some View {

        DashboardCard(
            title: "Items",
            systemImage: "cart.fill"
        ) {

            if (expense.receiptItems ?? []).isEmpty {

                Text("No item details available.")
                    .foregroundStyle(.secondary)

            } else {

                VStack(alignment: .leading, spacing: 8) {

                    ForEach(expense.receiptItems ?? [], id: \.self) { item in
                        Text("• \(item)")
                    }

                }

            }

        }

    }

    private var askAICard: some View {

        DashboardCard(
            title: "Ask Apple Intelligence",
            systemImage: "sparkles"
        ) {

            VStack(alignment: .leading, spacing: 12) {

                TextField(
                    "Ask about this receipt...",
                    text: $question
                )
                .textFieldStyle(.roundedBorder)

                Button {

                    Task {

                        await askAI()

                    }

                } label: {

                    Label(
                        "Ask",
                        systemImage: "paperplane.fill"
                    )
                    .frame(maxWidth: .infinity)

                }
                .buttonStyle(.borderedProminent)
                .disabled(question.isEmpty || isAsking)

                if isAsking {

                    ProgressView("Thinking...")

                }

                if !answer.isEmpty {

                    Text(answer)
                        .textSelection(.enabled)

                }

            }

        }

    }

    private var actionButtons: some View {

        HStack {

            Button {

                showEdit = true

            } label: {

                Label("Edit", systemImage: "pencil")
                    .frame(maxWidth: .infinity)

            }
            .buttonStyle(.bordered)

            Button(role: .destructive) {

                modelContext.delete(expense)

                dismiss()

            } label: {

                Label("Delete", systemImage: "trash")
                    .frame(maxWidth: .infinity)

            }
            .buttonStyle(.bordered)

        }

    }

    private func detailRow(
        _ title: String,
        _ value: String
    ) -> some View {

        HStack {

            Text(title)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.semibold)

        }

    }

    @MainActor
    private func askAI() async {

        guard #available(macOS 26.0, iOS 26.0, *) else {

            answer = "Apple Intelligence unavailable."

            return

        }

        isAsking = true

        defer {

            isAsking = false

        }

        do {

            let assistant = AppleIntelligenceExpenseAssistant()

            answer = try await assistant.answer(
                question: question,
                expense: expense
            )

        } catch {

            answer = error.localizedDescription

        }

    }

}

#Preview {

    ExpenseDetailView(
        expense: Expense(
            title: "Weekly Groceries",
            merchant: "Sheng Siong",
            amount: 24.10,
            category: "Groceries"
        )
    )
    .modelContainer(for: Expense.self, inMemory: true)

}
