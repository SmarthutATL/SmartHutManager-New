import SwiftUI
import FirebaseFirestore

struct LeadDetailView: View {
    let lead: Lead
    @Environment(\.presentationMode) private var presentationMode
    @State private var isShowingDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Lead Info Card
                cardView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Lead Information")
                            .font(.headline)
                            .foregroundColor(.blue)

                        detailRow(icon: "person.fill", label: "Name", value: lead.name)
                        detailRow(icon: "envelope.fill", label: "Email", value: lead.email)
                        detailRow(icon: "phone.fill", label: "Phone", value: lead.phone)
                    }
                }

                // Pipeline & Score Card
                cardView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pipeline & Score")
                            .font(.headline)
                            .foregroundColor(.purple)

                        detailRow(icon: "chart.bar.fill", label: "Pipeline Stage", value: lead.pipelineStage)
                        detailRow(icon: "star.fill", label: "Score", value: "\(lead.score)")
                    }
                }

                // Activity Card
                cardView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Activity Details")
                            .font(.headline)
                            .foregroundColor(.orange)

                        detailRow(icon: "calendar", label: "Last Activity", value: lead.lastActivity.formatted())
                        detailRow(icon: "clock.fill", label: "Created At", value: lead.createdAt.formatted())
                    }
                }

                // Notes Card
                cardView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                            .foregroundColor(.green)

                        Text(lead.notes.isEmpty ? "No notes available." : lead.notes)
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(.top, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // Delete Button
                Button(action: {
                    isShowingDeleteConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete Lead")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(8)
                }
                .padding(.top, 16)
            }
            .padding()
        }
        .navigationTitle("Lead Details")
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .alert(isPresented: $isShowingDeleteConfirmation) {
            Alert(
                title: Text("Confirm Deletion"),
                message: Text("Are you sure you want to delete this lead? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    deleteLead()
                },
                secondaryButton: .cancel()
            )
        }
    }

    // MARK: - Helper Views
    private func cardView<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        VStack {
            content()
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.body)
                    .foregroundColor(.primary)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Delete Lead
    private func deleteLead() {
        guard let id = lead.id else { return }
        let db = Firestore.firestore()
        db.collection("leads").document(id).delete { error in
            if let error = error {
                print("Error deleting lead: \(error.localizedDescription)")
            } else {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
