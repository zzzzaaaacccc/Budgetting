//
//  BudgetCardView.swift
//  Budgetting
//
//  Created by Zacharie on 4/7/26.
//

import SwiftUI

struct BudgetCardView: View {

    let monthlyBudget: Double
    let totalSpent: Double

    private var remaining: Double {
        max(monthlyBudget - totalSpent, 0)
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 16) {

            Text("Monthly Budget")
                .font(.headline)

            Text(monthlyBudget,
                 format: .currency(code: "SGD"))
                .font(.largeTitle)
                .bold()

            Divider()

            HStack {

                VStack(alignment: .leading) {

                    Text("Spent")
                        .foregroundStyle(.secondary)

                    Text(totalSpent,
                         format: .currency(code: "SGD"))
                        .font(.title2)
                        .bold()

                }

                Spacer()

                VStack(alignment: .trailing) {

                    Text("Remaining")
                        .foregroundStyle(.secondary)

                    Text(remaining,
                         format: .currency(code: "SGD"))
                        .font(.title2)
                        .bold()

                }

            }

            ProgressView(
                value: totalSpent,
                total: monthlyBudget
            )

        }
        .padding()
        .background(.thinMaterial)
        .clipShape(
            RoundedRectangle(cornerRadius: 20)
        )

    }

}

#Preview {

    BudgetCardView(
        monthlyBudget: 1000,
        totalSpent: 326.45
    )

}
