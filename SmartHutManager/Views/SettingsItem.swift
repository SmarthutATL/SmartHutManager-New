import SwiftUI

struct SettingsItem: View {
    var icon: String
    var title: String
    var color: Color
    var toggle: Bool = false
    @State private var isOn: Bool = false

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 32, height: 32)
            Text(title)
                .font(.body)
            Spacer()

            if toggle {
                Toggle("", isOn: $isOn)
                    .labelsHidden()
            }

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .opacity(toggle ? 0 : 1)
        }
    }
}
