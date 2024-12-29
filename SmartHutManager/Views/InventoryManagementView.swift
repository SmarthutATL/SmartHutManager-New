import SwiftUI
import Foundation

struct InventoryManagementView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Inventory Overview Card
                cardView {
                    NavigationLink(destination: InventoryOverviewView()) {
                        SettingsItem(icon: "tray.full.fill", title: "Inventory Overview", color: .blue)
                    }
                }

                // Add Inventory Card
                cardView {
                    NavigationLink(destination: AddInventoryView()) {
                        SettingsItem(icon: "plus.circle.fill", title: "Add Inventory", color: .green)
                    }
                }

                // Manage Inventory Card
                cardView {
                    NavigationLink(destination: ManageInventoryView()) {
                        SettingsItem(icon: "slider.horizontal.3", title: "Manage Inventory", color: .orange)
                    }
                }

                // Reports Card
                cardView {
                    NavigationLink(destination: InventoryReportsView()) {
                        SettingsItem(icon: "doc.text.fill", title: "Inventory Reports", color: .purple)
                    }
                }
            }
            .padding(.horizontal, 16)
            .navigationTitle("Inventory Management")
        }
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }

    // Reusable card-style container
    private func cardView<Content: View>(
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}