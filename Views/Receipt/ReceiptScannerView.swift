//
//  ReceiptScannerView.swift
//  Budgetting
//
//  Created by Zacharie on 4/7/26.
//

import SwiftUI
import UniformTypeIdentifiers
import PhotosUI

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

                if let image = vm.image {

#if os(iOS)

                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 400)

#else

                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 400)

#endif

                } else {

                    ContentUnavailableView(
                        "No Receipt Selected",
                        systemImage: "doc.viewfinder",
                        description: Text("Choose a receipt to begin.")
                    )

                }

                if vm.isProcessing {

                    ProgressView("Scanning Receipt...")

                }

                if !vm.extractedText.isEmpty {

                    VStack(alignment: .leading, spacing: 16) {

                        Text("Receipt Summary")
                            .font(.headline)

                        LabeledContent("Merchant") {
                            Text(vm.parsedReceipt.merchant.isEmpty ? "-" : vm.parsedReceipt.merchant)
                        }

                        LabeledContent("Category") {
                            Text(vm.parsedReceipt.category)
                        }

                        LabeledContent("Total") {

                            if let total = vm.parsedReceipt.total {

                                Text(total, format: .currency(code: "SGD"))

                            } else {

                                Text("-")

                            }

                        }

                        Divider()

                        Text("OCR Text")
                            .font(.headline)

                        ScrollView {

                            Text(vm.extractedText)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)

                        }
                        .frame(height: 180)

                    }
                    .padding()
                    .background(.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                }

                Divider()

                PhotosPicker(
                    selection: $selectedPhoto,
                    matching: .images
                ) {

                    Label("Choose From Photos", systemImage: "photo")

                }

#if os(macOS)

                Button {

                    openFile()

                } label: {

                    Label("Choose From Files", systemImage: "folder")

                }

#else

                Button {

                    showFilePicker = true

                } label: {

                    Label("Choose From Files", systemImage: "folder")

                }

#endif

            }
            .padding()

        }
        .navigationTitle("Receipt Scanner")

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
