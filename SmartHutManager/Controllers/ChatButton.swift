import SwiftUI

struct ChatButton: View {
    var hasNewMessage: Bool
    var onTap: () -> Void

    @State private var isBlinking = false

    var body: some View {
        Button(action: {
            onTap()
            isBlinking = false // Stop blinking when the button is pressed
        }) {
            ZStack(alignment: .topTrailing) {
                // Chat Icon with blinking animation
                Image(systemName: "ellipsis.bubble.fill")
                    .font(.title2) // Matches AlertButton size
                    .foregroundColor(isBlinking ? Color.green : Color.blue)
                    .animation(
                        isBlinking ? .easeInOut(duration: 1).repeatForever(autoreverses: true) : .default,
                        value: isBlinking
                    )

                // New Message Badge
                if hasNewMessage {
                    Text("1") // Static count for new messages
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(5)
                        .background(Circle().fill(Color.red))
                        .offset(x: 8, y: -8)
                }
            }
        }
        .accessibilityLabel("Chat Support")
        .accessibilityHint("Tap to start a chat with customer support.")
        .onAppear {
            isBlinking = hasNewMessage // Start blinking if there are new messages
        }
        .onChange(of: hasNewMessage) { newValue in
            isBlinking = newValue // Update blinking state dynamically
        }
    }
}
