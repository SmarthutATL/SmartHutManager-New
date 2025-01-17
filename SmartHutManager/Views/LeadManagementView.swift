import SwiftUI
import FirebaseFirestore

struct LeadManagementView: View {
    @State private var leads: [Lead] = []
    @State private var searchQuery = ""
    @State private var isAddingLead = false
    @State private var selectedPipelineStage: String? = nil
    @State private var selectedCustomer: Customer? = nil
    @State private var isShowingCustomerList = false
    @State private var leadToDelete: Lead? = nil
    @State private var isShowingDeleteConfirmation = false

    private let pipelineStages = ["New", "Contacted", "In Progress", "Closed"]

    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                TextField("Search leads...", text: $searchQuery)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                // Customer Selection
                Button(action: {
                    isShowingCustomerList.toggle()
                }) {
                    HStack {
                        Text(selectedCustomer?.name ?? "Select Customer")
                            .font(.headline)
                        Spacer()
                        Image(systemName: "chevron.right").foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .sheet(isPresented: $isShowingCustomerList) {
                    CustomerPickerView(selectedCustomer: $selectedCustomer)
                }

                // Pipeline Stage Filter
                Picker("Pipeline Stage", selection: $selectedPipelineStage) {
                    Text("All").tag(nil as String?)
                    ForEach(pipelineStages, id: \.self) { stage in
                        Text(stage).tag(stage as String?)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                // Lead List
                List {
                    ForEach(filteredLeads, id: \.id) { lead in
                        NavigationLink(destination: LeadDetailView(lead: lead)) {
                            VStack(alignment: .leading) {
                                Text(lead.name)
                                    .font(.headline)
                                Text("Score: \(lead.score)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text("Pipeline: \(lead.pipelineStage)")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                leadToDelete = lead
                                isShowingDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())

                // Add Lead Button
                Button(action: {
                    isAddingLead = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add New Lead")
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Lead Management")
            .sheet(isPresented: $isAddingLead) {
                AddLeadView(existingCustomer: selectedCustomer) { newLead in
                    addLead(newLead)
                }
            }
            .onAppear(perform: fetchLeads)
            .alert(isPresented: $isShowingDeleteConfirmation) {
                Alert(
                    title: Text("Confirm Deletion"),
                    message: Text("Are you sure you want to delete this lead? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        if let lead = leadToDelete {
                            deleteLead(lead)
                        }
                    },
                    secondaryButton: .cancel {
                        leadToDelete = nil
                    }
                )
            }
        }
    }

    // Filter Leads by Search and Pipeline Stage
    private var filteredLeads: [Lead] {
        leads.filter { lead in
            (selectedPipelineStage == nil || lead.pipelineStage == selectedPipelineStage) &&
            (searchQuery.isEmpty || lead.name.localizedCaseInsensitiveContains(searchQuery))
        }
    }

    // Fetch Leads from Firestore
    private func fetchLeads() {
        let db = Firestore.firestore()
        db.collection("leads").order(by: "createdAt", descending: true).addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching leads: \(error.localizedDescription)")
                return
            }

            leads = snapshot?.documents.compactMap { document in
                var lead: Lead? = try? document.data(as: Lead.self)
                lead?.id = document.documentID
                return lead
            } ?? []
        }
    }

    // Add New Lead to Firestore
    private func addLead(_ lead: Lead) {
        let db = Firestore.firestore()
        do {
            let ref = try db.collection("leads").addDocument(from: lead)
            print("Lead added with ID: \(ref.documentID)")
        } catch {
            print("Error adding lead: \(error.localizedDescription)")
        }
    }

    // Delete Lead from Firestore
    private func deleteLead(_ lead: Lead) {
        guard let id = lead.id else { return }
        let db = Firestore.firestore()
        db.collection("leads").document(id).delete { error in
            if let error = error {
                print("Error deleting lead: \(error.localizedDescription)")
            } else {
                leads.removeAll { $0.id == id }
                leadToDelete = nil
            }
        }
    }
}
