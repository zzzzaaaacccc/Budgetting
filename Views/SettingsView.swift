//
//  SettingsView.swift
//  Budgetting
//
//  Created by Zacharie on 4/7/26.
//

import SwiftUI
import SwiftData

struct SettingsView: View {

    @Environment(\.modelContext)
    private var modelContext

    @Query
    private var budgets: [Budget]

    @State private var monthlyBudget = ""

    var body: some View {

        NavigationStack {

            Form {

                Section("Budget") {

                    TextField(
                        "Monthly Budget",
                        text: $monthlyBudget
                    )
#if os(iOS)
                    .keyboardType(.decimalPad)
#endif

                    Button("Save Budget") {

                        saveBudget()

                    }

                }

            }
            .navigationTitle("Settings")
            .onAppear {

                if let budget = budgets.first {

                    monthlyBudget = String(budget.monthlyBudget)

                }

            }

        }

    }

    private func saveBudget() {

        guard let value = Double(monthlyBudget) else {
            return
        }

        if let budget = budgets.first {

            budget.monthlyBudget = value

        } else {

            modelContext.insert(
                Budget(monthlyBudget: value)
            )

        }

    }

}

#Preview {

    SettingsView()
        .modelContainer(for: Budget.self, inMemory: true)

}
