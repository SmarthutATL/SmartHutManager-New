//
//  MessageDetailView.swift
//  SmartHutManager
//
//  Created by Darius Ogletree on 12/24/24.
//

import SwiftUI

struct MessageDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var conversation: Conversation

    @State private var messageText: String = ""
    @State private var selectedImage: UIImage? = nil
    @State private var isShowingImagePicker = false
    @State private var messages: [Message] = []

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(messages, id: \.id) { message in
                        HStack {
                            if message.sender == "admin" {
                                Spacer()
                                messageBubble(message)
                            } else {
                                messageBubble(message)
                                Spacer()
                            }
                        }
                    }
                    .onDelete(perform: deleteMessage)
                }
                .padding()
            }

            Divider()

            HStack {
                Button(action: { isShowingImagePicker.toggle() }) {
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .sheet(isPresented: $isShowingImagePicker) {
                    ImagePicker(selectedImage: $selectedImage)
                        .onDisappear {
                            if let image = selectedImage {
                                sendImageMessage(image)
                            }
                        }
                }

                TextField("Type a message", text: $messageText)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                Button(action: sendTextMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                }
            }
            .padding()
        }
        .navigationTitle(conversation.name ?? "Messages")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            messages = fetchMessages()
        }
    }

    private func fetchMessages() -> [Message] {
        return conversation.messages?.allObjects as? [Message] ?? []
    }

    private func messageBubble(_ message: Message) -> some View {
        VStack(alignment: .leading) {
            if let content = message.content {
                Text(content)
                    .padding()
                    .background(message.sender == "admin" ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                    .cornerRadius(10)
            }
            if let imageData = message.imageData, let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 200)
                    .cornerRadius(10)
            }
        }
    }

    private func deleteMessage(at offsets: IndexSet) {
        offsets.forEach { index in
            let message = messages[index]
            viewContext.delete(message)
        }
        do {
            try viewContext.save()
            messages = fetchMessages() // Refresh messages list
        } catch {
            print("Failed to delete message: \(error)")
        }
    }

    private func sendTextMessage() {
        guard !messageText.isEmpty else { return }

        let newMessage = Message(context: viewContext)
        newMessage.id = UUID()
        newMessage.content = messageText
        newMessage.timestamp = Date()
        newMessage.sender = "admin"
        newMessage.conversation = conversation

        conversation.lastMessage = messageText
        conversation.timestamp = Date()

        do {
            try viewContext.save()
            messages.append(newMessage)
            messageText = ""
        } catch {
            print("Failed to send text message: \(error)")
        }
    }

    private func sendImageMessage(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }

        let newMessage = Message(context: viewContext)
        newMessage.id = UUID()
        newMessage.imageData = imageData
        newMessage.timestamp = Date()
        newMessage.sender = "admin"
        newMessage.conversation = conversation

        conversation.lastMessage = "Image sent"
        conversation.timestamp = Date()

        do {
            try viewContext.save()
            messages.append(newMessage)
        } catch {
            print("Failed to send image message: \(error)")
        }
    }
}
