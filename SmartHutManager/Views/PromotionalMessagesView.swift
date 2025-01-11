//
//  PromotionalMessagesView.swift
//  SmartHutManager
//
//  Created by Darius Ogletree on 1/11/25.
//

import SwiftUI

struct PromotionalMessagesView: View {
    @State private var message: String = ""
    @State private var recipients: [String] = []
    @State private var isSending = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Send Promotions")
                .font(.largeTitle)
                .bold()

            TextField("Enter message", text: $message)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button(action: sendPromotions) {
                HStack {
                    Image(systemName: "paperplane.fill")
                    Text("Send")
                        .fontWeight(.bold)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(message.isEmpty || recipients.isEmpty)
        }
        .padding()
        .navigationTitle("Promotions")
    }

    private func sendPromotions() {
        isSending = true
        // Logic to send promotional emails or texts
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isSending = false
            print("Promotions sent to \(recipients.count) recipients.")
        }
    }
}
