import SwiftUI

struct MessagesView: View {
    @State private var conversations: [Conversation] = [
        Conversation(id: UUID(), name: "John Doe", lastMessage: "Can we schedule a meeting?", timestamp: "10:45 AM"),
        Conversation(id: UUID(), name: "Jane Smith", lastMessage: "Invoice #123 has been approved.", timestamp: "9:30 AM")
    ]
    
    var body: some View {
        NavigationView {
            List(conversations) { conversation in
                NavigationLink(destination: MessageDetailView(conversation: conversation)) {
                    HStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 40, height: 40)
                            .overlay(Text(String(conversation.name.prefix(1)))
                                .font(.headline)
                                .foregroundColor(.white)
                            )
                        VStack(alignment: .leading) {
                            Text(conversation.name)
                                .font(.headline)
                            Text(conversation.lastMessage)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                        Spacer()
                        Text(conversation.timestamp)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Messages")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Action to start a new conversation
                    }) {
                        Label("New", systemImage: "square.and.pencil")
                    }
                }
            }
        }
    }
}

struct MessageDetailView: View {
    let conversation: Conversation
    
    @State private var messageText: String = ""
    @State private var messages: [String] = ["Hello, how can I help you?", "Can we schedule a meeting?"]
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(messages, id: \.self) { message in
                        HStack(alignment: .top) {
                            if message.starts(with: "Hello") {
                                Spacer()
                                Text(message)
                                    .padding()
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(10)
                            } else {
                                Text(message)
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(10)
                                Spacer()
                            }
                        }
                    }
                }
                .padding()
            }
            
            Divider()
            
            HStack {
                TextField("Type a message", text: $messageText)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                Button(action: {
                    guard !messageText.isEmpty else { return }
                    messages.append(messageText)
                    messageText = ""
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                }
            }
            .padding()
        }
        .navigationTitle(conversation.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct Conversation: Identifiable {
    let id: UUID
    let name: String
    let lastMessage: String
    let timestamp: String
}
