import SwiftUI

struct AlertButton: View {
    var alertCount: Int
    var hasNewAlert: Bool
    var onTap: () -> Void

    @State private var isBlinking = false

    var body: some View {
        Button(action: {
            onTap()
            isBlinking = false // Stop blinking when the button is pressed
        }) {
            ZStack(alignment: .topTrailing) {
                // Bell Icon with blinking animation
                Image(systemName: "bell.fill")
                    .font(.title)
                    .foregroundColor(isBlinking ? Color.red : Color.blue)
                    .animation(
                        isBlinking ? .easeInOut(duration: 1).repeatForever(autoreverses: true) : .default,
                        value: isBlinking
                    )

                // Notification Count Badge
                if alertCount > 0 {
                    Text("\(alertCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(5)
                        .background(Circle().fill(Color.red))
                        .offset(x: 8, y: -8)
                }
            }
        }
        .accessibilityLabel("Alerts")
        .accessibilityHint("Tap to view alerts")
        .onAppear {
            isBlinking = hasNewAlert // Start blinking if there are new alerts
        }
        .onChange(of: hasNewAlert) { newValue in
            isBlinking = newValue // Update blinking state dynamically
        }
    }
}
