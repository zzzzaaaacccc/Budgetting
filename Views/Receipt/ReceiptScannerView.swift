//
//  ReceiptScannerView.swift
//  Budgetting
//
//  Created by Zacharie on 4/7/26.
//

import SwiftUI
import UniformTypeIdentifiers
import PhotosUI
import SwiftData

#if os(macOS)
import AppKit
#endif

struct ReceiptScannerView: View {
    @State private var vm = ReceiptScannerViewModel()

#if !os(macOS)
    @State private var showFilePicker = false
#endif

    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                scannerCard

                if vm.isProcessing {
                    processingCard
                }

                if !vm.extractedText.isEmpty {
                    ReceiptReviewView(
                        receipt: $vm.parsedReceipt,
                        receiptImage: vm.imageData,
                        receiptText: vm.extractedText
                    )
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
            }
            .padding()
        }
        .navigationTitle("Scan Receipt")
        .onChange(of: selectedPhoto) { _, newValue in
            Task {
                guard
                    let newValue,
                    let data = try? await newValue.loadTransferable(type: Data.self)
                else {
                    return
                }

#if os(iOS)
                if let image = UIImage(data: data) {
                    vm.setImage(image)
                    await vm.scanReceipt()
                }
#else
                if let image = NSImage(data: data) {
                    vm.setImage(image)
                    await vm.scanReceipt()
                }
#endif
            }
        }

#if !os(macOS)
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [
                .image,
                .jpeg,
                .png,
                .heic,
                .pdf
            ]
        ) { result in
            switch result {
            case .success(let url):
                do {
                    let data = try Data(contentsOf: url)

                    if let image = UIImage(data: data) {
                        vm.setImage(image)

                        Task {
                            await vm.scanReceipt()
                        }
                    }
                } catch {
                    print(error)
                }

            case .failure(let error):
                print(error)
            }
        }
#endif
    }

    private var scannerCard: some View {
        VStack(spacing: 20) {
            if let image = vm.image {
#if os(iOS)
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 420)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
#else
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 420)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
#endif
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "doc.viewfinder")
                        .font(.system(size: 64))
                        .foregroundStyle(.secondary)

                    Text("Scan a Receipt")
                        .font(.title2)
                        .bold()

                    Text("Choose a receipt image from Photos or Files. Apple Intelligence will extract the expense details for review.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 420)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 48)
            }

            HStack(spacing: 12) {
                PhotosPicker(
                    selection: $selectedPhoto,
                    matching: .images
                ) {
                    Label("Photos", systemImage: "photo")
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel("Choose receipt from Photos")
                        .accessibilityHint("Select a receipt image from your photo library.")
                }
                .buttonStyle(.bordered)

#if os(macOS)
                Button {
                    openFile()
                } label: {
                    Label("Files", systemImage: "folder")
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel("Choose receipt from Files")
                        .accessibilityHint("Select a receipt image from your files.")
                }
                .buttonStyle(.borderedProminent)
#else
                Button {
                    showFilePicker = true
                } label: {
                    Label("Files", systemImage: "folder")
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel("Choose receipt from Files")
                        .accessibilityHint("Select a receipt image from your files.")
                }
                .buttonStyle(.borderedProminent)
#endif
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var processingCard: some View {
        HStack(spacing: 12) {
            ProgressView()
                .accessibilityLabel("Scanning receipt")
                .accessibilityHint("Apple Intelligence is extracting receipt details.")

            VStack(alignment: .leading, spacing: 4) {
                Text("Apple Intelligence is reading your receipt")
                    .font(.headline)

                Text("Extracting merchant, total, category and items.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#if os(macOS)
extension ReceiptScannerView {
    private func openFile() {
        let panel = NSOpenPanel()

        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false

        panel.allowedContentTypes = [
            .image,
            .jpeg,
            .png,
            .heic,
            .pdf
        ]

        if panel.runModal() == .OK,
           let url = panel.url {
            do {
                let data = try Data(contentsOf: url)

                if let image = NSImage(data: data) {
                    vm.setImage(image)

                    Task {
                        await vm.scanReceipt()
                    }
                }
            } catch {
                print(error)
            }
        }
    }
}
#endif

#Preview {
    ReceiptScannerView()
}
