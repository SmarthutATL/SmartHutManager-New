import SwiftUI

struct KnowledgeBaseView: View {
    let faqItems = [
        ("How to reset my password?", "Go to Settings > Account > Reset Password."),
        ("How to create a ticket?", "Navigate to Support and fill out the form.")
    ]
    
    var body: some View {
        NavigationView {
            List(faqItems, id: \.0) { (question, answer) in
                VStack(alignment: .leading) {
                    Text(question).font(.headline)
                    Text(answer).font(.subheadline).foregroundColor(.gray)
                }
            }
            .navigationTitle("Knowledge Base")
        }
    }
}
