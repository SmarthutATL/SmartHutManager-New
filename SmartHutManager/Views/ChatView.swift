import SwiftUI

struct ChatView: View {
    @State private var messages: [ChatMessage] = [
        ChatMessage(text: "Hi there! How can I assist you today?", isFromAI: true)
    ]
    
    @State private var userInput: String = ""

    var body: some View {
        NavigationView {
            VStack {
                // Chat Header
                Text("24/7 AI Live Chat")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)

                // Messages List
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(messages) { message in
                            HStack {
                                if message.isFromAI {
                                    AIMessageBubble(text: message.text)
                                    Spacer()
                                } else {
                                    Spacer()
                                    UserMessageBubble(text: message.text)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                }
                .background(Color(.systemGroupedBackground))
                .cornerRadius(12)
                .padding()

                // Input Field
                HStack {
                    TextField("Type your message...", text: $userInput)
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(20)
                        .padding(.horizontal)

                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 3)
                    }
                    .padding(.trailing)
                }
                .padding(.bottom)
            }
            .navigationTitle("AI Chat Support")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // Send user message and simulate AI response
    private func sendMessage() {
        guard !userInput.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        // Add user's message
        messages.append(ChatMessage(text: userInput, isFromAI: false))
        let userMessage = userInput
        userInput = ""

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let aiResponse = generateAIResponse(for: userMessage)
            messages.append(ChatMessage(text: aiResponse, isFromAI: true))
        }
    }

    // Example AI response generator
    private func generateAIResponse(for userMessage: String) -> String {
        if userMessage.lowercased().contains("hello") {
            return "Hello! How can I help you today?"
        } else if userMessage.lowercased().contains("issue") {
            return "I'm sorry to hear that you're experiencing an issue. Can you provide more details?"
        } else {
            return "Thank you for reaching out. I'll do my best to assist you with your query."
        }
    }
}

// MARK: - ChatMessage Model
struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isFromAI: Bool
}
// MARK: - User Message Bubble
struct UserMessageBubble: View {
    let text: String

    var body: some View {
        Text(text)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .frame(maxWidth: 250, alignment: .trailing)
    }
}

// MARK: - AI Message Bubble
struct AIMessageBubble: View {
    let text: String

    var body: some View {
        Text(text)
            .padding()
            .background(Color(.systemGray6))
            .foregroundColor(.black)
            .cornerRadius(12)
            .frame(maxWidth: 250, alignment: .leading)
    }
}
