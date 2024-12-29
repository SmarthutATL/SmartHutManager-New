import SwiftUI

struct GeneralSettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode: Bool = true

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    cardView {
                        HStack {
                            Image(systemName: "moon.circle.fill")
                                .foregroundColor(.yellow)
                                .frame(width: 32, height: 32)

                            VStack(alignment: .leading) {
                                Text("Dark Mode")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Text("Toggle between light and dark mode")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            Toggle("", isOn: $isDarkMode)
                                .labelsHidden()
                        }
                    }
                }
                .padding(.horizontal, 16)
                .navigationTitle("General Settings")
            }
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        }
    }

    // MARK: - Reusable Card Container
    private func cardView<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
