import SwiftUI

struct TechnicianManagementSection: View {
    @Binding var isShowingTradesmenList: Bool

    var body: some View {
        Section(header: Text("Technician Management")) {
            Button(action: {
                isShowingTradesmenList.toggle()
            }) {
                SettingsItem(icon: "person.crop.circle.fill", title: "Manage Technicians", color: .blue)
            }
        }
    }
}
