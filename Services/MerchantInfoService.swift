//
//  MerchantInfoService.swift
//  Budgetting
//
//  Created by Zacharie on 6/7/26.
//

import Foundation

struct MerchantInfo: Decodable {
    let title: String
    let description: String?
    let extract: String?
    let contentURLs: ContentURLs?

    enum CodingKeys: String, CodingKey {
        case title
        case description
        case extract
        case contentURLs = "content_urls"
    }
}

struct ContentURLs: Decodable {
    let desktop: PageURL?
}

struct PageURL: Decodable {
    let page: String?
}

final class MerchantInfoService {

    func fetchInfo(for merchant: String) async throws -> MerchantInfo {
        let cleanedMerchant = cleanedMerchantName(merchant)

        guard let encoded = cleanedMerchant.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://en.wikipedia.org/api/rest_v1/page/summary/\(encoded)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.setValue(
            "Budgetting/1.0 (zacharie.180803@gmail.com)",
            forHTTPHeaderField: "User-Agent"
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(MerchantInfo.self, from: data)
    }

    private func cleanedMerchantName(_ merchant: String) -> String {
        let upper = merchant.uppercased()

        if upper.contains("STARBUCKS") {
            return "Starbucks"
        }

        if upper.contains("SHENG") || upper.contains("SENG") {
            return "Sheng Siong"
        }

        if upper.contains("NTUC") || upper.contains("FAIRPRICE") {
            return "NTUC FairPrice"
        }

        if upper.contains("MCDONALD") {
            return "McDonald's"
        }

        if upper.contains("KFC") {
            return "KFC"
        }

        if upper.contains("GRAB") {
            return "Grab"
        }

        return merchant
    }
}
