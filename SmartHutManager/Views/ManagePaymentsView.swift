import SwiftUI
import CoreData

struct ManagePaymentsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("isDarkMode") private var isDarkMode: Bool = true // Track dark mode state

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Navigation Cards
                    cardView {
                        NavigationLink(destination: UploadQRCodeView()) {
                            SettingsItem(
                                icon: "qrcode.viewfinder",
                                title: "Upload QR Codes",
                                color: .green
                            )
                            .foregroundColor(isDarkMode ? .white : .black)
                        }
                    }

                    cardView {
                        NavigationLink(destination: GenerateLinksView(viewContext: viewContext)) {
                            SettingsItem(
                                icon: "link.circle.fill",
                                title: "Generate Payment Links",
                                color: .blue
                            )
                            .foregroundColor(isDarkMode ? .white : .black)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20) // Ensure some space below the title but not excessive
            }
            .background(Color(UIColor.systemBackground).ignoresSafeArea())
            .navigationTitle("Manage Payments") // Proper navigation bar title
            .navigationBarTitleDisplayMode(.inline) // Align title properly
        }
    }

    // Reusable card-style container
    private func cardView<Content: View>(
        isGold: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        ZStack {
            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding()
            .background(
                LinearGradient(
                    gradient: isGold
                        ? Gradient(colors: [Color.yellow.opacity(0.8), Color.orange.opacity(0.8)])
                        : Gradient(colors: [Color(.secondarySystemBackground), Color(.secondarySystemBackground)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
}
