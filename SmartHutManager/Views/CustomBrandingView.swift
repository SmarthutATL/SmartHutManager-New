import SwiftUI

struct CustomBrandingView: View {
    @State private var isShowingImagePicker = false
    @State private var selectedLogo: UIImage? = nil
    @AppStorage("isDarkMode") private var isDarkMode: Bool = true // Track dark mode state

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Upload Logo Section
                cardView {
                    Button(action: {
                        isShowingImagePicker.toggle()
                    }) {
                        SettingsItem(icon: "photo.fill", title: "Upload Logo", color: .purple)
                            .foregroundColor(isDarkMode ? .white : .black)
                    }
                }

                // Additional branding cards (if needed) can be added here
                cardView {
                    NavigationLink(destination: Text("Placeholder for another branding option")) {
                        SettingsItem(icon: "paintbrush.fill", title: "Custom Colors", color: .blue)
                            .foregroundColor(isDarkMode ? .white : .black)
                    }
                }
            }
            .padding(.horizontal, 16)
            .navigationTitle("Custom Branding")
            .sheet(isPresented: $isShowingImagePicker) {
                ImagePicker(selectedImage: $selectedLogo)
            }
        }
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }

    // Reusable card-style container
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
