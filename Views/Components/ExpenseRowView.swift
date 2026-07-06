//
//  ExpenseRowView.swift
//  Budgetting
//
//  Created by Zacharie on 4/7/26.
//

import SwiftUI

#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct ExpenseRowView: View {

    let expense: Expense

    private var categoryIcon: String {

        switch expense.category {

        case "Food":
            return "fork.knife"

        case "Groceries":
            return "cart.fill"

        case "Transport":
            return "car.fill"

        case "Shopping":
            return "bag.fill"

        case "Bills":
            return "doc.text.fill"

        case "Entertainment":
            return "gamecontroller.fill"

        case "Healthcare":
            return "cross.case.fill"

        default:
            return "creditcard.fill"

        }

    }

    var body: some View {

        HStack(spacing: 16) {

            receiptThumbnail

            VStack(alignment: .leading, spacing: 6) {

                Text(expense.title)
                    .font(.headline)
                    .lineLimit(1)

                Text(expense.merchant)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(expense.category)
                    .font(.caption)
                    .foregroundStyle(.tertiary)

            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {

                Text(
                    expense.amount,
                    format: .currency(code: "SGD")
                )
                .fontWeight(.semibold)

                Text(
                    expense.date,
                    format: .dateTime.day().month().year()
                )
                .font(.caption)
                .foregroundStyle(.secondary)

            }

        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))

    }

    @ViewBuilder
    private var receiptThumbnail: some View {

        if
            let data = expense.receiptImage {

            #if os(macOS)

            if let image = NSImage(data: data) {

                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

            } else {

                placeholder

            }

            #else

            if let image = UIImage(data: data) {

                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

            } else {

                placeholder

            }

            #endif

        } else {

            placeholder

        }

    }

    private var placeholder: some View {

        Image(systemName: categoryIcon)
            .font(.title2)
            .frame(width: 60, height: 60)
            .background(.blue.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 10))

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
