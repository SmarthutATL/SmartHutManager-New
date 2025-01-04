import SwiftUI

struct AlertButton: View {
    var alertCount: Int // Change from `@Binding` to a plain `Int`
    var onTap: () -> Void

    var body: some View {
        Button(action: {
            onTap()
        }) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell.fill")
                    .font(.title2)
                    .foregroundColor(.blue)

                if alertCount > 0 {
                    Text("\(alertCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(5)
                        .background(Circle().fill(Color.red))
                        .offset(x: 10, y: -10)
                }
            }
        }
        .accessibilityLabel("Alerts")
        .accessibilityHint("Tap to view alerts")
    }
}
