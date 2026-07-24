# Budgetting

> An AI-powered native expense management application built with SwiftUI, SwiftData, Vision OCR, and Apple Foundation Models.

---

## Overview

Budgetting is a native AI-powered expense management application for Apple platforms.

Instead of manually entering expenses, users simply scan a receipt. The application uses Apple's Vision framework for OCR, Foundation Models for structured receipt understanding, and SwiftData for local persistence.

To improve reliability on long and complex receipts, the application processes OCR text in multiple AI stages, including chunked receipt understanding and dedicated payment extraction before presenting results for user review.

The project explores modern Apple platform development while demonstrating production-oriented AI engineering practices including MVVM architecture, Swift Concurrency, accessibility, and on-device AI.

---

# Features

## AI Receipt Scanning

- Scan receipts directly from Photos or Files
- Optical Character Recognition using Vision
- AI-powered structured receipt understanding using Apple Foundation Models
- Chunked AI processing for long OCR documents
- Dedicated AI payment extraction for improved total accuracy
- Review and edit AI-extracted information before saving
- Automatic extraction of:
  - Merchant
  - Total amount
  - Category
  - Purchased items
- Review and edit extracted information before saving

---

## Expense Management

- Store expenses using SwiftData
- Edit existing expenses
- Delete expenses
- Search expenses
- Filter by category
- Store original receipt images
- Preserve OCR text for future AI queries

---

## Dashboard

- Monthly spending summary
- Budget progress ring
- Spending by category
- Largest spending category
- Spending insights generated using Apple Intelligence

---

## Apple Intelligence

### AI Receipt Parsing

Transforms raw OCR text into structured expense information using Apple's Foundation Models.

### Spending Insights

Generates personalised insights based on spending behaviour rather than generic financial advice.

### Ask About Your Receipt

Users can ask natural language questions such as:

- What did I buy?
- How much did I spend?
- Which merchant was this from?
- Summarise this receipt.
- Was this mostly groceries or household items?

---

# Screenshots

## Dashboard

![Dashboard](Screenshots/dashboard.png)

---

## Expense List

![Expenses](Screenshots/expenses.png)

---

## Receipt Scanner

![Receipt Scanner](Screenshots/scan_receipt.png)

---

## Expense Detail

![Expense Detail](Screenshots/detailed_expenses_from_image.png)

---

## AI Insights

![Insights](Screenshots/insights.png)

---

## Natural Language Expense Queries

![Ask AI](Screenshots/ask.png)

---

# Architecture

```
                      SwiftUI Views
                            │
                            ▼
                    ViewModels (MVVM)
                            │
        ┌───────────────────┼───────────────────┐
        ▼                   ▼                   ▼
 Vision OCR         AI Receipt Pipeline    Expense Services
        │                   │                   │
        ▼                   ▼                   ▼
 Text Extraction   Foundation Models      SwiftData
                           │
        ┌──────────────────┴──────────────────┐
        ▼                                     ▼
 Chunked Receipt Parsing          Payment Evidence Extraction
                           │
                           ▼
                    Structured Receipt
```

---

# Technology Stack

### Languages

- Swift

### UI

- SwiftUI

### Persistence

- SwiftData

### Artificial Intelligence

- Apple Foundation Models
- LanguageModelSession
- Guided Generation (@Generable, @Guide)
- Prompt Engineering

### OCR

- Vision Framework

### Charts

- Swift Charts

### Concurrency

- Swift Concurrency
- async / await

### Testing

- Swift Testing
- XCUITest

### Architecture

- MVVM

### Accessibility

- VoiceOver support
- Accessibility labels
- Accessibility hints

---

# Engineering Highlights

This project demonstrates:

- Native Apple platform development
- Modern SwiftUI architecture
- On-device AI integration
- OCR document processing using Vision
- On-device LLM integration with Apple Foundation Models
- Chunked AI processing for large documents
- Structured generation using @Generable and @Guide
- AI-assisted financial information extraction
- Local-first data persistence
- Receipt image storage
- Natural language querying
- Unit testing
- UI testing
- Accessibility support

---

# Engineering Challenges and Solutions

### Processing Long Receipts

Large digital receipts could exceed the context window of Apple's on-device Foundation Models.

To support longer receipts, the OCR output is split into smaller sections and processed using multiple AI sessions before being consolidated into a single structured receipt.

### Improving Financial Accuracy

Receipts often contain many monetary values such as subtotals, taxes, discounts and final totals.

Instead of relying on a single extraction pass, the application performs a dedicated AI payment extraction step to identify the final amount paid before verifying it against the original OCR text. This significantly improves reliability for complex receipts while keeping the workflow fully AI-powered.

### Human-in-the-Loop Review

All AI-generated receipt information is presented to the user for review and editing before being stored in SwiftData, preventing incorrect OCR or AI output from being persisted automatically.

---

# Testing

The project includes automated tests covering:

- Dashboard calculations
- Expense analysis
- Receipt parsing
- Business logic
- UI launch tests

---

# Requirements

- Xcode 26+
- iOS 26+
- macOS 26+
- Apple Foundation Models supported device
