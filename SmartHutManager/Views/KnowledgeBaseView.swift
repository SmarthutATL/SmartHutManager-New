import SwiftUI

struct KnowledgeBaseView: View {
    let faqItems = [
        ("How to reset my password?", "Go to Settings > Account > Reset Password."),
        ("How to create a ticket?", "Navigate to Support and fill out the form."),
        ("How to update my profile?", "Go to Settings > Profile > Edit Profile."),
        ("How to contact support?", "Use the 24/7 AI chat or create a ticket in the Support section.")
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible())], spacing: 16) {
                    ForEach(faqItems, id: \.0) { (question, answer) in
                        NavigationLink(destination: KnowledgeBaseDetailView(question: question, answer: answer)) {
                            KnowledgeBaseCardView(question: question)
                        }
                        .buttonStyle(PlainButtonStyle()) // Remove default NavigationLink style
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
            }
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
            .navigationTitle("Knowledge Base")
        }
    }
}

struct KnowledgeBaseCardView: View {
    let question: String

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.white, Color(.systemGray6)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 8) {
                Text(question)
                    .font(.headline)
                    .foregroundColor(.black)
                    .lineLimit(2)
                    .padding(.bottom, 4)
                Text("Tap to learn more")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding()
        }
        .frame(height: 100) // Fixed height for consistent card sizes
    }
}
