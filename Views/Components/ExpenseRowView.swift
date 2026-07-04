//
//  ExpenseRowView.swift
//  Budgetting
//
//  Created by Zacharie on 4/7/26.
//

import SwiftUI

struct ExpenseRowView: View {

    let expense: Expense

    private var categoryIcon: String {
        switch expense.category {
        case "Food":
            return "fork.knife"
        case "Transport":
            return "car.fill"
        case "Shopping":
            return "bag.fill"
        case "Bills":
            return "doc.text.fill"
        case "Entertainment":
            return "gamecontroller.fill"
        default:
            return "creditcard.fill"
        }
    }

    var body: some View {

        HStack(spacing: 16) {

            Image(systemName: categoryIcon)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(.blue.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {

                Text(expense.title)
                    .font(.headline)

                Text(expense.merchant)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

            }

            Spacer()

            VStack(alignment: .trailing) {

                Text(expense.amount,
                     format: .currency(code: "SGD"))
                    .bold()

                Text(expense.date,
                     format: .dateTime.day().month())
                    .font(.caption)
                    .foregroundStyle(.secondary)

            }

        }
        .padding(.vertical, 4)

    }

}

#Preview {

    ExpenseRowView(
        expense: Expense(
            title: "Coffee",
            merchant: "Starbucks",
            amount: 6.50,
            category: "Food",
            date: .now
        )
    )

}
