//
//  ContentView.swift
//  Budgetting
//
//  Created by Zacharie on 4/7/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {

    @State private var showingAddExpense = false

    var body: some View {

        NavigationViewWrapper {

            List {

                NavigationLink {
                    DashboardView()
                } label: {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }

                NavigationLink {
                    ExpenseListView()
                } label: {
                    Label("Expenses", systemImage: "list.bullet")
                }

                NavigationLink {
                    ReceiptScannerView()
                } label: {
                    Label("Scan Receipt", systemImage: "doc.viewfinder")
                }

                NavigationLink {

                    SettingsView()

                } label: {

                    Label("Settings", systemImage: "gearshape")

                }

            }

#if os(macOS)
            .navigationSplitViewColumnWidth(min: 220, ideal: 250)
#endif

        }
        .toolbar {

#if os(iOS)
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
#endif

            ToolbarItem {

                Button {

                    showingAddExpense = true

                } label: {

                    Label("Add Expense", systemImage: "plus")

                }

            }

        }
        .sheet(isPresented: $showingAddExpense) {

            AddExpenseView()

        }

    }

}

fileprivate struct NavigationViewWrapper<Content: View>: View {

    let content: () -> Content

    var body: some View {

#if os(macOS)

        NavigationSplitView {

            content()

        } detail: {

            ContentUnavailableView(
                "Select a Section",
                systemImage: "sidebar.left"
            )

        }

#else

        NavigationStack {

            content()

        }

#endif

    }

}

#Preview {
    ContentView()
        .modelContainer(for: Expense.self, inMemory: true)
}
