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
                // Larger Bell Icon
                Image(systemName: "bell.fill")
                    .font(.title) // Made the icon larger
                    .foregroundColor(isBlinking ? Color.red : Color.blue) // Alternate between red and blue
                    .animation(
                        isBlinking ? .easeInOut(duration: 1).repeatForever(autoreverses: true) : .default,
                        value: isBlinking
                    )

                // Larger Notification Count
                if alertCount > 0 {
                    Text("\(alertCount)")
                        .font(.caption) // Slightly larger font
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(6) // Increase padding for the badge
                        .background(Circle().fill(Color.red))
                        .offset(x: 10, y: -10) // Adjust offset for the larger badge
                }
            }
        }
        .accessibilityLabel("Alerts")
        .accessibilityHint("Tap to view alerts")
        .onAppear {
            if hasNewAlert {
                isBlinking = true
            }
        }
        .onChange(of: hasNewAlert) { newValue in
            isBlinking = newValue
        }
    }
}
