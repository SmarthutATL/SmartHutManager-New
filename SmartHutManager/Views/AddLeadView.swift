import SwiftUI

struct AddLeadView: View {
    @Environment(\.presentationMode) private var presentationMode
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var pipelineStage = "New"
    @State private var notes = ""
    @State private var direct = true
    @State private var selectedCustomer: Customer? = nil
    @State private var isShowingCustomerList = false

    private let pipelineStages = ["New", "Contacted", "Quoted", "In Progress", "Closed", "Hired"]

    var onSave: (Lead) -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Customer Picker Card
                    cardView {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Select Customer")
                                .font(.headline)
                                .foregroundColor(.blue)

                            Button(action: {
                                isShowingCustomerList.toggle()
                            }) {
                                HStack {
                                    Text(selectedCustomer?.name ?? "No customer selected")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                            }
                            .sheet(isPresented: $isShowingCustomerList) {
                                CustomerPickerView(selectedCustomer: $selectedCustomer)
                                    .onDisappear {
                                        populateFieldsFromCustomer()
                                    }
                            }
                        }
                    }

                    // Lead Information Card
                    cardView {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Lead Information")
                                .font(.headline)
                                .foregroundColor(.blue)

                            detailInputRow(icon: "person.fill", placeholder: "Name", text: $name)
                            detailInputRow(icon: "envelope.fill", placeholder: "Email", text: $email, keyboardType: .emailAddress)
                            detailInputRow(icon: "phone.fill", placeholder: "Phone", text: $phone, keyboardType: .phonePad)
                        }
                    }

                    // Pipeline & Type Card
                    cardView {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Pipeline & Type")
                                .font(.headline)
                                .foregroundColor(.purple)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(pipelineStages, id: \.self) { stage in
                                        FilterChip(title: stage, isSelected: pipelineStage == stage) {
                                            pipelineStage = stage
                                        }
                                    }
                                }
                                .padding(.vertical, 5)
                            }

                            Toggle(isOn: $direct) {
                                Text(direct ? "Direct Lead" : "Opportunity")
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }
                        }
                    }

                    // Notes Card
                    cardView {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)
                                .foregroundColor(.green)

                            TextEditor(text: $notes)
                                .frame(height: 100)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                )
                        }
                    }

                    // Save Button
                    Button(action: saveLead) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save Lead")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(name.isEmpty || email.isEmpty || phone.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(8)
                        .disabled(name.isEmpty || email.isEmpty || phone.isEmpty)
                    }
                    .padding(.top, 16)
                }
                .padding()
            }
            .navigationTitle("Add New Lead")
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        }
    }

    // MARK: - Populate Fields from Selected Customer
    private func populateFieldsFromCustomer() {
        if let customer = selectedCustomer {
            name = customer.name ?? ""
            email = customer.email ?? ""
            phone = customer.phoneNumber ?? ""
        }
    }

    // MARK: - Save Lead
    private func saveLead() {
        let newLead = Lead(
            id: UUID().uuidString,
            name: name,
            email: email,
            phone: phone,
            pipelineStage: pipelineStage,
            score: 0,
            lastActivity: Date(),
            notes: notes,
            createdAt: Date(),
            direct: direct
        )
        onSave(newLead)
        presentationMode.wrappedValue.dismiss()
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

    private func detailInputRow(icon: String, placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType = .default) -> some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)

            TextField(placeholder, text: text)
                .keyboardType(keyboardType)
                .textContentType(.name)
                .padding(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
        }
    }
}
