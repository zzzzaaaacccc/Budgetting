//
//  AskExpensesView.swift
//  Budgetting
//
//  Created by Zacharie on 6/7/26.
//

import SwiftUI
import SwiftData

struct AskExpensesView: View {

    @Query(sort: \Expense.date, order: .reverse)
    private var expenses: [Expense]

    @State private var question = ""

    @State private var answer = ""

    @State private var isLoading = false

    var body: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: 24) {

                Text("Ask Your Expenses")
                    .font(.largeTitle)
                    .bold()

                Text("""
Ask questions about your spending using natural language.

Examples:

• How much did I spend at Starbucks?
• What was my biggest purchase?
• Which category do I spend the most on?
• What did I buy at Sheng Siong?
• When was my last grocery purchase?
""")
                .foregroundStyle(.secondary)

                TextField(
                    "Ask a question...",
                    text: $question,
                    axis: .vertical
                )
                .textFieldStyle(.roundedBorder)

                Button {

                    Task {

                        await askAI()

                    }

                } label: {

                    Label(
                        "Ask Apple Intelligence",
                        systemImage: "sparkles"
                    )
                    .frame(maxWidth: .infinity)

                }
                .buttonStyle(.borderedProminent)
                .disabled(question.isEmpty || expenses.isEmpty)

                if isLoading {

                    ProgressView()

                }

                if !answer.isEmpty {

                    VStack(alignment: .leading, spacing: 12) {

                        Label(
                            "Answer",
                            systemImage: "brain"
                        )
                        .font(.headline)

                        Text(answer)
                            .textSelection(.enabled)

                    }
                    .padding()
                    .background(.gray.opacity(0.1))
                    .clipShape(
                        RoundedRectangle(cornerRadius: 12)
                    )

                }

            }
            .padding()

        }
        .navigationTitle("Ask")

    }

    @MainActor
    private func askAI() async {

        guard #available(macOS 26.0, iOS 26.0, *) else {

            answer = "Apple Intelligence is unavailable."

            return

        }

        isLoading = true

        do {

            let assistant = AppleIntelligenceExpenseAssistant()

            answer = try await assistant.answer(
                question: question,
                expenses: expenses
            )

        } catch {

            answer = error.localizedDescription

        }

        isLoading = false

    }

}

#Preview {

    AskExpensesView()
        .modelContainer(for: Expense.self, inMemory: true)

}
