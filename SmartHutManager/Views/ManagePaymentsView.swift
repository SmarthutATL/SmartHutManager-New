import SwiftUI
import CoreData

struct ManagePaymentsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("isDarkMode") private var isDarkMode: Bool = true // Track dark mode state

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) { // Increased spacing for better readability
                    // Upload QR Codes Card
                    tappableCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SettingsItem(
                                icon: "qrcode.viewfinder",
                                title: "Upload QR Codes",
                                color: .green
                            )
                            Text("Add or update QR codes for payment methods like Zelle or PayPal.")
                                .font(.body)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.leading)
                        }
                    } destination: {
                        UploadQRCodeView()
                    }

                    // Generate Payment Links Card
                    tappableCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SettingsItem(
                                icon: "link.circle.fill",
                                title: "Generate Payment Links",
                                color: .blue
                            )
                            Text("Create and share payment links for quick and secure transactions.")
                                .font(.body)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.leading)
                        }
                    } destination: {
                        GenerateLinksView(viewContext: viewContext)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(Color(UIColor.systemBackground).ignoresSafeArea())
            .navigationTitle("Manage Payments")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Reusable tappable card with animation and navigation
    private func tappableCard<Content: View, Destination: View>(
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        NavigationLink(destination: destination()) {
            VStack(alignment: .leading, spacing: 16) {
                content()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
                    .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
            )
            .scaleEffect(1.0) // Default scale effect
            .contentShape(Rectangle()) // Makes the entire card tappable
            .animation(nil, value: UUID()) // Prevents unwanted animation interference
        }
        .buttonStyle(PlainButtonStyle()) // Prevents NavigationLink default styling
        .simultaneousGesture(
            TapGesture()
                .onEnded {
                    // Optionally add tap feedback here if needed
                }
        )
    }
}
