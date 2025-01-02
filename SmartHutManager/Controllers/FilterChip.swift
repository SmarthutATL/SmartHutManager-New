import SwiftUI

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var isEnabled: Bool = true // Optional; default is true
    let action: () -> Void

    var body: some View {
        Button(action: {
            if isEnabled { action() }
        }) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                .foregroundColor(isEnabled ? (isSelected ? .blue : .primary) : .secondary)
                .clipShape(Capsule())
                .opacity(isEnabled ? 1.0 : 0.5) // Visually indicate disabled state
        }
        .disabled(!isEnabled) // Disable the button when isEnabled is false
    }
}
