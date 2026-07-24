//
//  ReceiptScannerView.swift
//  Budgetting
//
//  Created by Zacharie on 4/7/26.
//

import PDFKit
import SwiftUI
import UniformTypeIdentifiers

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct ReceiptScannerView: View {

    @StateObject private var viewModel =
        ReceiptScannerViewModel()

    @State private var showFilePicker = false

    @State private var fileName: String?

    @State private var showReceiptReview = false

    @State private var receiptImageData: Data?

    var body: some View {

        ScrollView {

            VStack(spacing: 30) {

                receiptImageSection

                if viewModel.isProcessing {

                    processingSection
                }

                if let errorMessage =
                    viewModel.errorMessage {

                    errorSection(
                        message: errorMessage
                    )
                }

                if hasReceiptDetails {

                    receiptDetailsSection

                    reviewButton
                }

                if !viewModel.extractedText.isEmpty {

                    rawTextSection
                }

                chooseReceiptButton

                if viewModel.image != nil {

                    clearReceiptButton
                }

                if let fileName {

                    Text("Selected: \(fileName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("Receipt Scanner")
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [
                .image,
                .pdf
            ],
            allowsMultipleSelection: false
        ) { result in

            handleFileImport(result)
        }
        .sheet(
            isPresented: $showReceiptReview
        ) {

            ReceiptReviewView(
                receipt: Binding(
                    get: {
                        viewModel.receipt
                    },
                    set: {
                        viewModel.receipt = $0
                    }
                ),
                receiptImage: receiptImageData,
                receiptText: viewModel.extractedText
            )
        }
    }

    @ViewBuilder
    private var receiptImageSection: some View {

        if let image = viewModel.image {

#if os(iOS)
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 450)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 16
                    )
                )
#elseif os(macOS)
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 450)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 16
                    )
                )
#endif

        } else {

            ContentUnavailableView(
                "No Receipt Selected",
                systemImage: "doc.viewfinder",
                description: Text(
                    "Choose an image or PDF receipt to begin scanning."
                )
            )
        }
    }

    private var processingSection: some View {

        VStack(spacing: 12) {

            ProgressView()
                .controlSize(.large)

            Text(
                viewModel.parsingMethod.isEmpty
                ? "Scanning receipt..."
                : viewModel.parsingMethod
            )
            .font(.headline)

            Text(
                "This may take a moment for longer receipts."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.regularMaterial)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
    }

    private func errorSection(
        message: String
    ) -> some View {

        VStack(spacing: 16) {

            ContentUnavailableView(
                "Unable to Scan Receipt",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )

            if !viewModel.extractedText.isEmpty {

                Button {

                    viewModel.retryParsing()

                } label: {

                    Label(
                        "Retry Apple Intelligence Parsing",
                        systemImage: "arrow.clockwise"
                    )
                }
                .buttonStyle(.bordered)
            }

            Button {

                showFilePicker = true

            } label: {

                Label(
                    "Choose Another Receipt",
                    systemImage: "folder"
                )
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
    }

    private var receiptDetailsSection: some View {

        VStack(alignment: .leading, spacing: 16) {

            Text("Receipt Details")
                .font(.title2)
                .fontWeight(.semibold)

            if !viewModel.parsingMethod.isEmpty {

                Label(
                    viewModel.parsingMethod,
                    systemImage:
                        viewModel.parsingMethod.contains(
                            "Apple Intelligence"
                        )
                        ? "sparkles"
                        : "gearshape.2"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            receiptRow(
                title: "Merchant",
                value: displayedValue(
                    viewModel.receipt.merchant
                )
            )

            receiptRow(
                title: "Title",
                value: displayedValue(
                    viewModel.receipt.title
                )
            )

            receiptRow(
                title: "Date",
                value: displayedValue(
                    viewModel.receipt.date
                )
            )

            receiptRow(
                title: "Category",
                value: displayedValue(
                    viewModel.receipt.category
                )
            )

            if let subtotal =
                viewModel.receipt.subtotal {

                receiptRow(
                    title: "Subtotal",
                    value: formattedCurrency(
                        subtotal
                    )
                )
            }

            if let tax =
                viewModel.receipt.tax {

                receiptRow(
                    title: "Tax",
                    value: formattedCurrency(
                        tax
                    )
                )
            }

            if let total =
                viewModel.receipt.total {

                receiptRow(
                    title: "Total",
                    value: formattedCurrency(
                        total
                    ),
                    isHighlighted: true
                )

            } else {

                receiptRow(
                    title: "Total",
                    value: "Not detected"
                )
            }

            if !viewModel.receipt.items.isEmpty {

                Divider()

                VStack(
                    alignment: .leading,
                    spacing: 10
                ) {

                    Text("Items")
                        .font(.headline)

                    ForEach(
                        Array(
                            viewModel.receipt.items
                                .enumerated()
                        ),
                        id: \.offset
                    ) { _, item in

                        Label(
                            item,
                            systemImage:
                                "checkmark.circle"
                        )
                        .font(.subheadline)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
    }

    private var reviewButton: some View {

        Button {

            showReceiptReview = true

        } label: {

            Label(
                "Review & Save Expense",
                systemImage:
                    "square.and.arrow.down"
            )
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(
            viewModel.isProcessing ||
            viewModel.extractedText.isEmpty
        )
    }

    private var rawTextSection: some View {

        DisclosureGroup(
            "View OCR Text"
        ) {

            ScrollView {

                Text(
                    viewModel.extractedText
                )
                .font(
                    .system(
                        .caption,
                        design: .monospaced
                    )
                )
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .textSelection(.enabled)
                .padding(.top)
            }
            .frame(maxHeight: 260)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
    }

    private var chooseReceiptButton: some View {

        Button {

            showFilePicker = true

        } label: {

            Label(
                viewModel.image == nil
                ? "Choose Receipt"
                : "Choose Another Receipt",
                systemImage: "folder"
            )
            .font(.headline)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }

    private var clearReceiptButton: some View {

        Button(
            role: .destructive
        ) {

            clearReceipt()

        } label: {

            Label(
                "Clear Receipt",
                systemImage: "trash"
            )
        }
    }

    private var hasReceiptDetails: Bool {

        let merchant =
            viewModel.receipt.merchant
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        let title =
            viewModel.receipt.title
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        return !merchant.isEmpty ||
            !title.isEmpty ||
            viewModel.receipt.total != nil ||
            viewModel.receipt.subtotal != nil ||
            viewModel.receipt.tax != nil ||
            !viewModel.receipt.items.isEmpty
    }

    private func receiptRow(
        title: String,
        value: String,
        isHighlighted: Bool = false
    ) -> some View {

        HStack(
            alignment: .firstTextBaseline
        ) {

            Text(title)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .fontWeight(
                    isHighlighted
                    ? .bold
                    : .medium
                )
                .multilineTextAlignment(
                    .trailing
                )
        }
    }

    private func displayedValue(
        _ value: String
    ) -> String {

        let cleanedValue =
            value.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return cleanedValue.isEmpty
            ? "Not detected"
            : cleanedValue
    }

    private func formattedCurrency(
        _ amount: Double
    ) -> String {

        amount.formatted(
            .currency(
                code: "SGD"
            )
        )
    }

    private func handleFileImport(
        _ result: Result<
            [URL],
            Error
        >
    ) {

        switch result {

        case .success(let urls):

            guard let url =
                urls.first
            else {

                return
            }

            fileName =
                url.lastPathComponent

            loadFile(
                from: url
            )

        case .failure(let error):

            viewModel.errorMessage =
                "File import failed: \(error.localizedDescription)"
        }
    }

    private func loadFile(
        from url: URL
    ) {

        let hasSecurityAccess =
            url.startAccessingSecurityScopedResource()

        defer {

            if hasSecurityAccess {

                url.stopAccessingSecurityScopedResource()
            }
        }

        do {

            let contentType =
                try url.resourceValues(
                    forKeys: [
                        .contentTypeKey
                    ]
                )
                .contentType

            if contentType?.conforms(
                to: .pdf
            ) == true {

                guard let image =
                    loadPDF(
                        from: url
                    )
                else {

                    viewModel.errorMessage =
                        "The PDF could not be converted into an image."

                    return
                }

                receiptImageData =
                    platformImageData(
                        from: image
                    )

                viewModel.setImage(
                    image
                )

                return
            }

            let data =
                try Data(
                    contentsOf: url
                )

#if os(iOS)
            guard let image =
                UIImage(
                    data: data
                )
            else {

                viewModel.errorMessage =
                    "The selected file is not a supported image."

                return
            }
#elseif os(macOS)
            guard let image =
                NSImage(
                    data: data
                )
            else {

                viewModel.errorMessage =
                    "The selected file is not a supported image."

                return
            }
#endif

            receiptImageData =
                data

            viewModel.setImage(
                image
            )

        } catch {

            viewModel.errorMessage =
                "Failed to load file: \(error.localizedDescription)"
        }
    }

    private func loadPDF(
        from url: URL
    ) -> PlatformImage? {

        guard let document =
                PDFDocument(
                    url: url
                ),
              let firstPage =
                document.page(
                    at: 0
                )
        else {

            return nil
        }

        let pageBounds =
            firstPage.bounds(
                for: .mediaBox
            )

        let maximumDimension:
            CGFloat = 2400

        let scale =
            min(
                maximumDimension /
                    pageBounds.width,
                maximumDimension /
                    pageBounds.height
            )

        let thumbnailSize =
            CGSize(
                width:
                    pageBounds.width *
                    scale,
                height:
                    pageBounds.height *
                    scale
            )

        return firstPage.thumbnail(
            of: thumbnailSize,
            for: .mediaBox
        )
    }

    private func platformImageData(
        from image: PlatformImage
    ) -> Data? {

#if os(iOS)

        return image.jpegData(
            compressionQuality: 0.9
        )

#elseif os(macOS)

        guard let tiffData =
                image.tiffRepresentation,
              let bitmap =
                NSBitmapImageRep(
                    data: tiffData
                )
        else {

            return nil
        }

        return bitmap.representation(
            using: .jpeg,
            properties: [
                .compressionFactor: 0.9
            ]
        )

#endif
    }

    private func clearReceipt() {

        fileName = nil

        receiptImageData = nil

        showReceiptReview = false

        viewModel.clearReceipt()
    }
}

#Preview {

    NavigationStack {

        ReceiptScannerView()
    }
}
