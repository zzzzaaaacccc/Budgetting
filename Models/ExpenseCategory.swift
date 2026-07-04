//
//  ExpenseCategory.swift
//  Budgetting
//
//  Created by Zacharie on 4/7/26.
//

import Foundation

enum ExpenseCategory: String, CaseIterable, Codable, Identifiable {

    case food = "Food"
    case groceries = "Groceries"
    case transport = "Transport"
    case shopping = "Shopping"
    case entertainment = "Entertainment"
    case bills = "Bills"
    case health = "Health"
    case education = "Education"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {

        switch self {

        case .food:
            return "fork.knife"

        case .groceries:
            return "cart.fill"

        case .transport:
            return "car.fill"

        case .shopping:
            return "bag.fill"

        case .entertainment:
            return "gamecontroller.fill"

        case .bills:
            return "doc.text.fill"

        case .health:
            return "cross.case.fill"

        case .education:
            return "book.fill"

        case .other:
            return "creditcard.fill"

        }

    }

}
