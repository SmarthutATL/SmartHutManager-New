import SwiftUI

struct TechDetailView: View {
    let tradesman: Tradesmen

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Technician Details")) {
                    HStack {
                        Text("Full Name")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(tradesman.name ?? "Unknown")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Job Title")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(tradesman.jobTitle ?? "Unknown")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Phone Number")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(tradesman.phoneNumber ?? "Unknown")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Address")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(tradesman.address ?? "Unknown")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Email")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(tradesman.email ?? "Unknown")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Technician Details")
        }
    }
}
