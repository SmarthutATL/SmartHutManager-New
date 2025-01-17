import SwiftUI
import FirebaseFirestore

struct LeadManagementView: View {
    @State private var leads: [Lead] = []
    @State private var searchQuery = ""
    @State private var isAddingLead = false
    @State private var selectedPipelineStage: String? = nil
    @State private var selectedLeadType: String? = "All Leads" // Direct Leads or Opportunities
    @State private var leadToEdit: Lead? = nil
    @State private var leadToDelete: Lead? = nil
    @State private var isShowingDeleteConfirmation = false

    private let pipelineStages = ["New", "Contacted", "Quoted", "In Progress", "Closed", "Hired"]
    private let leadTypes = ["All Leads", "Direct Leads", "Opportunities"]

    var body: some View {
        NavigationView {
            VStack {
                // Dashboard
                leadDashboard
                    .padding(.vertical, 10)
                
                // Lead Type Filter
                leadTypeFilter
                    .padding(.horizontal)

                // Search Bar
                TextField("Search leads...", text: $searchQuery)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                // Pipeline Stage Filter
                pipelineStageFilterChips
                    .padding(.horizontal)

                // Lead List
                if filteredLeads.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredLeads, id: \.id) { lead in
                                leadCard(lead: lead)
                                    .contextMenu {
                                        Button("Edit") {
                                            leadToEdit = lead
                                        }
                                        Button("Delete", role: .destructive) {
                                            leadToDelete = lead
                                            isShowingDeleteConfirmation = true
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Add Lead Button
                Button(action: {
                    isAddingLead = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add New Lead")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Lead Management")
            .sheet(isPresented: $isAddingLead) {
                AddLeadView { newLead in
                    addLead(newLead)
                }
            }
            .sheet(item: $leadToEdit) { lead in
                EditLeadView(lead: lead) { updatedLead in
                    updateLead(updatedLead)
                }
            }
            .alert(isPresented: $isShowingDeleteConfirmation) {
                Alert(
                    title: Text("Confirm Deletion"),
                    message: Text("Are you sure you want to delete this lead?"),
                    primaryButton: .destructive(Text("Delete")) {
                        if let lead = leadToDelete {
                            deleteLead(lead)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
            .onAppear(perform: fetchLeads)
        }
    }

    // MARK: - Dashboard
    private var leadDashboard: some View {
        HStack {
            dashboardStat(title: "Total Leads", value: "\(leads.count)")
            dashboardStat(title: "Hired", value: "\(leads.filter { $0.pipelineStage == "Hired" }.count)")
            dashboardStat(title: "Opportunities", value: "\(leads.filter { leadType(for: $0) == "Opportunities" }.count)")
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func dashboardStat(title: String, value: String) -> some View {
        VStack {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Lead Type Filter
    private var leadTypeFilter: some View {
        Picker("Lead Type", selection: $selectedLeadType) {
            ForEach(leadTypes, id: \.self) { type in
                Text(type).tag(type)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }

    // MARK: - Pipeline Stage Filter Chips
    private var pipelineStageFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All Stages", isSelected: selectedPipelineStage == nil) {
                    selectedPipelineStage = nil
                }
                ForEach(pipelineStages, id: \.self) { stage in
                    FilterChip(title: stage, isSelected: selectedPipelineStage == stage) {
                        selectedPipelineStage = selectedPipelineStage == stage ? nil : stage
                    }
                }
            }
            .padding(.vertical, 5)
        }
    }

    // MARK: - Lead Card
    private func leadCard(lead: Lead) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(lead.name)
                    .font(.headline)
                Spacer()
                Text("Score: \(lead.score)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Text(lead.pipelineStage)
                .font(.subheadline)
                .foregroundColor(stageColor(lead.pipelineStage))
            HStack {
                Button(action: { callCustomer(lead.phone) }) {
                    Image(systemName: "phone.fill")
                }
                Button(action: { emailCustomer(lead.email) }) {
                    Image(systemName: "envelope.fill")
                }
                Spacer()
                Text(lead.lastActivity.formatted())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Filtering Logic
    private var filteredLeads: [Lead] {
        leads.filter { lead in
            (selectedLeadType == "All Leads" || leadType(for: lead) == selectedLeadType) &&
            (selectedPipelineStage == nil || lead.pipelineStage == selectedPipelineStage) &&
            (searchQuery.isEmpty || lead.name.localizedCaseInsensitiveContains(searchQuery))
        }
    }

    private func leadType(for lead: Lead) -> String {
        lead.direct ? "Direct Leads" : "Opportunities"
    }
    
    
    private func stageColor(_ stage: String) -> Color {
        switch stage {
        case "New": return .blue
        case "Contacted": return .orange
        case "Quoted": return .purple
        case "In Progress": return .green
        case "Closed", "Hired": return .gray
        default: return .secondary
        }
    }

    // MARK: - Actions
    private func callCustomer(_ phone: String) {
        print("Calling \(phone)")
    }

    private func emailCustomer(_ email: String) {
        print("Emailing \(email)")
    }

    private func fetchLeads() {
        let db = Firestore.firestore()
        db.collection("leads").addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching leads: \(error.localizedDescription)")
                return
            }
            leads = snapshot?.documents.compactMap { document in
                var lead = try? document.data(as: Lead.self)
                lead?.id = document.documentID
                return lead
            } ?? []
        }
    }

    private func addLead(_ lead: Lead) {
        let db = Firestore.firestore()
        do {
            _ = try db.collection("leads").addDocument(from: lead)
        } catch {
            print("Error adding lead: \(error.localizedDescription)")
        }
    }

    private func updateLead(_ lead: Lead) {
        let db = Firestore.firestore()
        guard let id = lead.id else { return }
        do {
            try db.collection("leads").document(id).setData(from: lead)
        } catch {
            print("Error updating lead: \(error.localizedDescription)")
        }
    }

    private func deleteLead(_ lead: Lead) {
        guard let id = lead.id else {
            print("Error: Lead ID is nil. Cannot delete.")
            return
        }
        let db = Firestore.firestore()
        db.collection("leads").document(id).delete { error in
            if let error = error {
                print("Error deleting lead: \(error.localizedDescription)")
            } else {
                print("Lead successfully deleted: \(id)")
                // Update local state
                leads.removeAll { $0.id == id }
            }
        }
    }

    private var emptyStateView: some View {
        VStack {
            Text("No leads available.")
                .font(.title2)
                .foregroundColor(.secondary)
        }
        .frame(maxHeight: .infinity)
    }
}
