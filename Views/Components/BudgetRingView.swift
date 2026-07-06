//
//  BudgetRingView.swift
//  Budgetting
//
//  Created by Zacharie on 6/7/26.
//

import SwiftUI

struct BudgetRingView: View {

    let progress: Double
    let amountRemaining: Double

    var body: some View {

        ZStack {

            Circle()
                .stroke(
                    .gray.opacity(0.15),
                    lineWidth: 12
                )

            Circle()
                .trim(
                    from: 0,
                    to: min(progress, 1)
                )
                .stroke(
                    progressColor,
                    style: StrokeStyle(
                        lineWidth: 12,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(
                    .easeInOut(duration: 0.8),
                    value: progress
                )

            VStack(spacing: 4) {

                Text("\(Int(progress * 100))%")
                    .font(.title2.bold())

                Text("Remaining")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(
                    amountRemaining,
                    format: .currency(code: "SGD")
                )
                .font(.caption.bold())

            }

        }
        .frame(width: 120, height: 120)

    }

    private var progressColor: Color {

        switch progress {

        case ..<0.6:
            return .green

        case ..<0.9:
            return .orange

        default:
            return .red

        }

    }

}

#Preview {

    BudgetRingView(
        progress: 0.72,
        amountRemaining: 280
    )

}
