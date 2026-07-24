//
//  ParsedReceipt.swift
//  Budgetting
//
//  Created by Zacharie on 4/7/26.
//

import Foundation
import FoundationModels

@Generable
struct ParsedReceipt {

    @Guide(
        description:
            """
            The name of the merchant or business that issued the receipt.

            Use the actual business name rather than an address,
            invoice heading, payment provider or product name.

            Examples:
            FairPrice, Starbucks, Grab, Watsons.
            """
    )
    var merchant: String

    @Guide(
        description:
            """
            A short, useful description of the expense.

            Base the title on the merchant and type of purchase.

            Examples:
            Grocery Order, Coffee Purchase, Taxi Ride,
            Pharmacy Purchase.

            Do not use Total, Order Total or Tax Invoice
            as the expense title.
            """
    )
    var title: String

    @Guide(
        description:
            """
            The final amount actually paid by the customer.

            Copy this value only from an explicitly labelled final amount,
            such as:

            - Order Total
            - Grand Total
            - Amount Paid
            - Total Paid
            - Final Total
            - Net Total
            - Payment Total

            Never calculate this value.

            Never add subtotal and tax.

            Never add GST to a total when GST is already included.

            Never use the subtotal, tax amount, service fee,
            discount, individual item price or pre-discount total.

            For example, when the receipt shows:

            Subtotal: 71.65
            Service fee: 3.99
            Discount: -11.00
            Order total: 64.64

            The correct final total is 64.64.
            """
    )
    var total: Double?

    @Guide(
        description:
            """
            The receipt or transaction date formatted as dd/MM/yyyy.

            Convert recognised formats where possible.

            Return an empty string when no reliable receipt date
            is explicitly present.
            """
    )
    var date: String

    @Guide(
        description:
            """
            The most appropriate expense category.

            Use exactly one of:

            Food
            Groceries
            Transport
            Shopping
            Entertainment
            Healthcare
            Bills
            Other

            Classification rules:

            - Supermarkets and grocery stores, including FairPrice,
              NTUC, Cold Storage and Sheng Siong, are Groceries.
            - Restaurants, cafés and takeaway food are Food.
            - Taxis, ride-hailing, buses and trains are Transport.
            - Pharmacies, clinics and medical purchases are Healthcare.
            - Utilities, telecommunications and subscriptions are Bills.
            - Retail products that are not groceries are Shopping.
            """
    )
    var category: String

    @Guide(
        description:
            """
            The names of genuine products or services purchased.

            Include only purchased items.

            Exclude:

            - merchant names
            - addresses
            - telephone numbers
            - invoice numbers
            - receipt numbers
            - payment methods
            - masked card numbers
            - subtotal lines
            - tax or GST lines
            - total lines
            - service fees
            - delivery fees
            - discounts
            - promotion descriptions
            - loyalty points
            - terms and conditions

            Do not include duplicate items unless the receipt clearly
            represents distinct purchased products.
            """
    )
    var items: [String]

    @Guide(
        description:
            """
            The amount explicitly labelled Subtotal or equivalent.

            This represents the amount before some combination of
            discounts, service fees or delivery fees.

            It is not necessarily the final amount paid.

            Copy the explicitly printed subtotal only.
            Never calculate it from item prices.
            """
    )
    var subtotal: Double?

    @Guide(
        description:
            """
            The explicitly printed monetary GST or tax amount.

            Return a value only when the receipt clearly shows
            GST or tax as a currency amount.

            Do not calculate tax from a percentage.

            A line containing only 9% GST does not provide
            a monetary tax amount.

            Do not assume tax must be added to the subtotal or total,
            because GST may already be included in displayed prices.
            """
    )
    var tax: Double?

    @Guide(
        description:
            """
            Return an empty string.

            The application assigns the original OCR text after
            structured receipt generation is complete.
            Do not reproduce the supplied OCR text in this property.
            """
    )
    var rawText: String

    static let empty = ParsedReceipt(
        merchant: "",
        title: "",
        total: nil,
        date: "",
        category: "Other",
        items: [],
        subtotal: nil,
        tax: nil,
        rawText: ""
    )
}
