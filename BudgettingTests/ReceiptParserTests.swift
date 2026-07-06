//
//  ReceiptParserTests.swift
//  Budgetting
//
//  Created by Zacharie on 6/7/26.
//

import Testing
@testable import Budgetting

struct ReceiptParserTests {

    @Test
    func parsesStarbucksReceipt() {
        let parser = ReceiptParser()

        let text = """
        STARBUCKS
        LATTE
        TOTAL
        8.60
        """

        let receipt = parser.parse(text: text)

        #expect(receipt.merchant == "Starbucks")
        #expect(receipt.category == "Food")
        #expect(receipt.title == "Meal")
    }

    @Test
    func parsesShengSiongAsGroceries() {
        let parser = ReceiptParser()

        let text = """
        SENG SKNG SUPERMARKET
        LAY'S CLASSIC 170G
        TOTAL AMOUNT
        24.10
        """

        let receipt = parser.parse(text: text)

        #expect(receipt.merchant == "Sheng Siong")
        #expect(receipt.category == "Groceries")
        #expect(receipt.title == "Grocery Shopping")
    }

    @Test
    func extractsItemsAndRemovesReceiptNoise() {
        let parser = ReceiptParser()

        let text = """
        SHENG SIONG
        Cashier: A123
        LAY'S CLASSIC 170G
        GST AMT
        8888232013010
        COCONUT WATER 350ML
        TOTAL
        24.10
        """

        let receipt = parser.parse(text: text)

        #expect(receipt.items.contains("LAY'S CLASSIC 170G"))
        #expect(receipt.items.contains("COCONUT WATER 350ML"))
        #expect(!receipt.items.contains("Cashier: A123"))
        #expect(!receipt.items.contains("GST AMT"))
    }

    @Test
    func unknownMerchantFallsBackToFirstLine() {
        let parser = ReceiptParser()

        let text = """
        RANDOM STORE
        ITEM A
        TOTAL
        4.50
        """

        let receipt = parser.parse(text: text)

        #expect(receipt.merchant == "RANDOM STORE")
        #expect(receipt.category == "Other")
    }
}
