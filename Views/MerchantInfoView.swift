//
//  MerchantInfoView.swift
//  Budgetting
//
//  Created by Zacharie on 6/7/26.
//

import SwiftUI

struct MerchantInfoView: View {

    let merchant: String

    @State private var info: MerchantInfo?
    @State private var isLoading = false
    @State private var errorMessage = ""

    private let service = MerchantInfoService()

    var body: some View {
        DashboardCard(
            title: "Merchant Intelligence",
            systemImage: "building.2.fill"
        ) {
            if isLoading {
                ProgressView("Loading merchant info...")
            } else if let info {
                VStack(alignment: .leading, spacing: 10) {
                    Text(info.title)
                        .font(.headline)

                    if let description = info.description {
                        Text(description.capitalized)
                            .foregroundStyle(.secondary)
                    }

                    if let extract = info.extract {
                        Text(extract)
                            .font(.callout)
                            .lineLimit(5)
                    }

                    if let page = info.contentURLs?.desktop?.page,
                       let url = URL(string: page) {
                        Link("Read more", destination: url)
                    }
                }
            } else if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundStyle(.secondary)
            } else {
                Text("No merchant information loaded.")
                    .foregroundStyle(.secondary)
            }
        }
        .task(id: merchant) {
            await loadMerchantInfo()
        }
    }

    @MainActor
    private func loadMerchantInfo() async {
        guard !merchant.isEmpty else {
            return
        }

        isLoading = true
        errorMessage = ""

        do {
            info = try await service.fetchInfo(for: merchant)
        } catch {
            errorMessage = "Merchant information is unavailable."
        }

        isLoading = false
    }
}
