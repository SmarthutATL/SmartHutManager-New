import SwiftUI
import CoreData

struct MessagesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Conversation.timestamp, ascending: false)]
    ) private var conversations: FetchedResults<Conversation>
    
    @State private var isCreatingNewConversation = false

    var body: some View {
        NavigationView {
            VStack {
                if conversations.isEmpty {
                    VStack {
                        Text("No Messages")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Start a conversation with a technician or customer.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                } else {
                    List {
                        ForEach(conversations) { conversation in
                            NavigationLink(destination: MessageDetailView(conversation: conversation)) {
                                HStack {
                                    Circle()
                                        .fill(roleColor(for: conversation.participants ?? ""))
                                        .frame(width: 40, height: 40)
                                        .overlay(Text(initials(for: conversation.name ?? "Unknown"))
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        )
                                    VStack(alignment: .leading) {
                                        Text(conversation.name ?? "Unknown")
                                            .font(.headline)
                                        Text(conversation.lastMessage ?? "No messages yet")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    if let timestamp = conversation.timestamp {
                                        Text(formatDate(timestamp))
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        .onDelete(perform: deleteConversation)
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Messages")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isCreatingNewConversation = true }) {
                        Label("New", systemImage: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $isCreatingNewConversation) {
                NewConversationView(onSave: {
                    isCreatingNewConversation = false
                })
            }
        }
    }

    private func deleteConversation(at offsets: IndexSet) {
        offsets.forEach { index in
            let conversation = conversations[index]
            viewContext.delete(conversation)
        }
        do {
            try viewContext.save()
        } catch {
            print("Failed to delete conversation: \(error)")
        }
    }

    private func initials(for name: String?) -> String {
        guard let name = name else { return "?" }
        return name.split(separator: " ").compactMap { $0.first?.uppercased() }.joined()
    }

    private func roleColor(for participants: String) -> Color {
        if participants.contains("admin") {
            return .blue
        } else if participants.contains("Technician") {
            return .green
        } else if participants.contains("Customer") {
            return .orange
        } else {
            return .gray
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
