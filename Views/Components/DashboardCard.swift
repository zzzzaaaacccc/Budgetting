//
//  DashboardCard.swift
//  Budgetting
//
//  Created by Zacharie on 6/7/26.
//

import SwiftUI

struct DashboardCard<Content: View>: View {

    let title: String
    let systemImage: String
    let content: Content

    init(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 16) {

            Label(title, systemImage: systemImage)
                .font(.headline)

            content

        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.quaternary, lineWidth: 1)
        )

    }

}

#Preview {

    DashboardCard(
        title: "Monthly Budget",
        systemImage: "creditcard.fill"
    ) {

        Text("$1,000")

    }

}
