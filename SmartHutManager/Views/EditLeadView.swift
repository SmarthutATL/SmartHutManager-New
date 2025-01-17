import SwiftUI

struct EditLeadView: View {
    @State var lead: Lead
    var onSave: (Lead) -> Void
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Lead Details")) {
                    TextField("Name", text: $lead.name)
                    TextField("Email", text: $lead.email)
                    TextField("Phone", text: $lead.phone)
                        .keyboardType(.phonePad)
                }
                
                Section(header: Text("Pipeline Stage")) {
                    Picker("Stage", selection: $lead.pipelineStage) {
                        ForEach(["New", "Contacted", "Quoted", "In Progress", "Closed", "Hired"], id: \.self) { stage in
                            Text(stage).tag(stage)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Score")) {
                    Stepper(value: $lead.score, in: 0...100) {
                        Text("Score: \(lead.score)")
                    }
                }
            }
            .navigationTitle("Edit Lead")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(lead)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
