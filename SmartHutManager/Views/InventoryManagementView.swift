import SwiftUI
import Foundation

struct InventoryManagementView: View {
    @Environment(\.managedObjectContext) private var viewContext // Access Core Data context

    var body: some View {
        ScrollView {
            VStack(spacing: 24) { // Increased spacing between cards for better readability
                // Inventory Overview Card
                cardView {
                    NavigationLink(destination: InventoryOverviewView(context: viewContext)) {
                        VStack(alignment: .leading, spacing: 12) {
                            SettingsItem(icon: "tray.full.fill", title: "Inventory Overview", color: .blue)
                            Text("View and manage all inventory items, including quantities and assignments.")
                                .font(.body) // Larger font size
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }

                // Reports Card
                cardView {
                    NavigationLink(destination: InventoryReportsView(context: viewContext)) {
                        VStack(alignment: .leading, spacing: 12) {
                            SettingsItem(icon: "doc.text.fill", title: "Inventory Reports", color: .purple)
                            Text("Generate detailed reports on inventory usage and stock levels.")
                                .font(.body) // Larger font size
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
                cardView {
                    NavigationLink(destination: AnalyticsDashboardView(context: viewContext)) {
                        VStack(alignment: .leading, spacing: 12) {
                            SettingsItem(icon: "chart.bar.xaxis", title: "Analytics Dashboard", color: .orange)
                            Text("Visualize trends, stock levels, and total inventory value.")
                                .font(.body)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
            }
            .padding(.horizontal, 20) // Added wider padding for more consistent alignment
            .navigationTitle("Inventory Management")
        }
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }

    // Reusable card-style container
    private func cardView<Content: View>(
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) { // Increased spacing for a cleaner look
            content()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3) // Slightly stronger shadow for emphasis
        )
    }
}
