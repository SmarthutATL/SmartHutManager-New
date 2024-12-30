import SwiftUI
import CoreData

struct NewWorkOrderView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode

    // Work Order Details
    @State private var selectedCategory: JobCategoryEntity? = nil
    @State private var selectedJob: JobOptionEntity? = nil
    @State private var workOrderDescription = ""
    @State private var status = "Open"
    @State private var selectedCustomer: Customer?
    @State private var isShowingCustomerList = false
    @State private var isShowingAddCustomerView = false
    @State private var serviceTime = Date()
    @State private var notes = ""
    @State private var isCallback = false

    @State private var tasks: [TaskItem] = []
    @State private var newTaskName = ""
    @State private var newTaskDescription = ""
    @State private var isShowingIncompleteAlert = false
    @State private var alertMessage = ""
    @State private var isSaving = false

    var selectedDate: Date
    @State private var serviceDate: Date

    // Inventory and Materials
    @State private var selectedMaterials: [Material] = []
    @State private var initialInventorySnapshot: [String: Int16] = [:]

    @FetchRequest(
        entity: JobCategoryEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \JobCategoryEntity.name, ascending: true)]
    ) var categories: FetchedResults<JobCategoryEntity>

    @FetchRequest(
        entity: Tradesmen.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Tradesmen.name, ascending: true)]
    ) var fetchedTradesmen: FetchedResults<Tradesmen>

    @FetchRequest(
        entity: Inventory.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Inventory.name, ascending: true)]
    ) var inventoryItems: FetchedResults<Inventory>

    @FetchRequest(
        entity: Customer.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Customer.name, ascending: true)]
    ) var customers: FetchedResults<Customer>

    @State private var selectedTradesmen: Set<Tradesmen> = []

    init(selectedDate: Date) {
        self.selectedDate = selectedDate
        self._serviceDate = State(initialValue: selectedDate)
    }

    var body: some View {
        NavigationView {
            Form {
                assignCustomerSection
                callbackSection
                workOrderDetailsSection
                workOrderDescriptionSection
                tasksSection
                selectMaterialsSection
                assignTechnicianSection
                saveButtonSection
            }
            .navigationTitle("Create Work Order")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        resetMaterialSelections()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                takeInventorySnapshot()
            }
        }
    }

    // MARK: - Sections
    private var assignCustomerSection: some View {
        Section(header: Text("Assign Customer")) {
            Button(action: { isShowingAddCustomerView.toggle() }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                    Text("Add New Customer")
                }
            }
            Button(action: { isShowingCustomerList.toggle() }) {
                HStack {
                    Text(selectedCustomer?.name ?? "Select Customer")
                    Spacer()
                    Image(systemName: "chevron.right").foregroundColor(.gray)
                }
            }
        }
    }

    private var callbackSection: some View {
        Section(header: Text("Is this a Callback?")) {
            Toggle(isOn: $isCallback) {
                Text(isCallback ? "Yes" : "No")
                    .foregroundColor(isCallback ? .green : .red)
            }
        }
    }

    private var workOrderDetailsSection: some View {
        Section(header: Text("Work Order Details")) {
            Picker("Category", selection: $selectedCategory) {
                if categories.isEmpty {
                    Text("No categories available").foregroundColor(.gray)
                } else {
                    ForEach(categories, id: \.self) { category in
                        Text(category.name ?? "Unknown Category").tag(category as JobCategoryEntity?)
                    }
                }
            }
            .onChange(of: selectedCategory) { _, _ in
                selectedJob = nil
                workOrderDescription = ""
            }
            if let selectedCategory = selectedCategory {
                let jobs = fetchJobsForCategory(selectedCategory)
                Picker("Select Job", selection: $selectedJob) {
                    ForEach(jobs, id: \.self) { job in
                        Text(job.name ?? "Unknown Job").tag(job as JobOptionEntity?)
                    }
                }
                .onChange(of: selectedJob) { newValue, _ in
                    if let job = newValue {
                        workOrderDescription = job.jobDescription ?? ""
                    }
                }
            }
            DatePicker("Date of Service", selection: $serviceDate, displayedComponents: .date)
            DatePicker("Time of Service", selection: $serviceTime, displayedComponents: .hourAndMinute)
            ZStack(alignment: .topLeading) {
                if notes.isEmpty {
                    Text("Customer preferences, ex. take shoes off while on carpet")
                        .foregroundColor(.gray)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 8)
                }
                TextEditor(text: $notes)
                    .frame(height: 100)
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.gray, lineWidth: 1))
            }
        }
    }

    private var workOrderDescriptionSection: some View {
        Section(header: Text("Work Order Description")) {
            ZStack(alignment: .topLeading) {
                if workOrderDescription.isEmpty {
                    Text("Enter a detailed description of the work")
                        .foregroundColor(.gray)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 8)
                }
                TextEditor(text: $workOrderDescription)
                    .frame(height: 120)
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.gray, lineWidth: 1))
            }
        }
    }

    private var tasksSection: some View {
        Section(header: Text("Tasks")) {
            ForEach(tasks.indices, id: \.self) { index in
                VStack(alignment: .leading) {
                    Text(tasks[index].name).font(.headline)
                    Text(tasks[index].description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .swipeActions {
                    Button(role: .destructive) { deleteTask(at: index) } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            VStack(alignment: .leading, spacing: 10) {
                TextField("Task Name", text: $newTaskName)
                TextField("Task Description", text: $newTaskDescription)
                Button(action: addTask) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Task")
                    }
                }
            }
        }
    }

    private var selectMaterialsSection: some View {
        Section(header: Text("Select Materials")) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(inventoryItems) { item in
                        HStack {
                            Text(item.name ?? "Unknown")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text("Qty: \(item.quantity)")
                                .font(.subheadline)
                                .frame(maxWidth: 80, alignment: .center)

                            Text("$\(item.price, specifier: "%.2f")")
                                .font(.subheadline)
                                .frame(maxWidth: 80, alignment: .trailing)

                            HStack(spacing: 10) {
                                Button(action: { addMaterialToWorkOrder(from: item) }) {
                                    Image(systemName: "plus.circle.fill")
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                        .foregroundColor(.green)
                                }

                                Button(action: { removeMaterialFromWorkOrder(material: item) }) {
                                    Image(systemName: "minus.circle.fill")
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                        .foregroundColor(.red)
                                }
                            }
                            .frame(maxWidth: 80, alignment: .trailing)
                        }
                        .padding(.vertical, 5)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            .frame(maxHeight: 300) // Adjust max height to fit your design
        }
    }

    private var assignTechnicianSection: some View {
        Section(header: Text("Assign Technician")) {
            ForEach(fetchedTradesmen, id: \.self) { tradesman in
                HStack {
                    Text(tradesman.name ?? "Unknown")
                    Spacer()
                    if selectedTradesmen.contains(tradesman) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                            .onTapGesture {
                                selectedTradesmen.remove(tradesman)
                            }
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(.gray)
                            .onTapGesture {
                                selectedTradesmen.insert(tradesman)
                            }
                    }
                }
            }
        }
    }

    private var saveButtonSection: some View {
        Section {
            Button(action: {
                if validateForm() { addWorkOrder() }
            }) {
                HStack {
                    if isSaving {
                        ProgressView()
                        Text("Saving...")
                    } else {
                        Image(systemName: "checkmark.circle")
                        Text("Save Work Order")
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(isSaving || !validateForm() ? Color.gray : Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isSaving || !validateForm())
        }
    }

    // MARK: - Helper Methods
    private func fetchJobsForCategory(_ category: JobCategoryEntity) -> [JobOptionEntity] {
        let fetchRequest: NSFetchRequest<JobOptionEntity> = JobOptionEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "category == %@", category)
        return (try? viewContext.fetch(fetchRequest)) ?? []
    }

    private func addMaterialToWorkOrder(from inventory: Inventory) {
        guard inventory.quantity > 0 else { return }

        // Deduct from inventory
        inventory.quantity -= 1

        // Add or update material in selectedMaterials
        if let index = selectedMaterials.firstIndex(where: { $0.name == inventory.name }) {
            selectedMaterials[index].quantity += 1
        } else {
            selectedMaterials.append(Material(name: inventory.name ?? "Unknown", price: inventory.price, quantity: 1))
        }

        // Save changes to Core Data
        saveInventoryChanges()
    }

    private func removeMaterialFromWorkOrder(material: Inventory) {
        guard let index = selectedMaterials.firstIndex(where: { $0.name == material.name }) else { return }

        selectedMaterials[index].quantity -= 1
        material.quantity += 1

        // Remove material from selectedMaterials if quantity is zero
        if selectedMaterials[index].quantity <= 0 {
            selectedMaterials.remove(at: index)
        }

        // Save changes to Core Data
        saveInventoryChanges()
    }
    
    private func saveInventoryChanges() {
        do {
            try viewContext.save()
        } catch {
            print("Failed to save inventory changes: \(error.localizedDescription)")
        }
    }
    private func resetMaterialSelections() {
        for material in selectedMaterials {
            if let inventoryItem = inventoryItems.first(where: { $0.name == material.name }) {
                inventoryItem.quantity += Int16(material.quantity)
            }
        }
        selectedMaterials.removeAll()
    }

    private func takeInventorySnapshot() {
        initialInventorySnapshot = inventoryItems.reduce(into: [:]) { result, item in
            result[item.name ?? ""] = item.quantity
        }
    }

  private func addWorkOrder() {
        isSaving = true // Start showing the spinner

        DispatchQueue.global(qos: .userInitiated).async {
            let fetchRequest: NSFetchRequest<WorkOrder> = NSFetchRequest(entityName: "WorkOrder")
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \WorkOrder.workOrderNumber, ascending: false)]
            fetchRequest.fetchLimit = 1

            do {
                // Get the highest work order number and calculate the next one
                let highestWorkOrder = try viewContext.fetch(fetchRequest).first
                let nextWorkOrderNumber = (highestWorkOrder?.workOrderNumber ?? 0) + 1

                // Create a new WorkOrder
                let newWorkOrder = WorkOrder(context: viewContext)
                newWorkOrder.category = selectedCategory?.name
                newWorkOrder.job = selectedJob
                newWorkOrder.workOrderDescription = workOrderDescription
                newWorkOrder.status = status
                newWorkOrder.date = serviceDate
                newWorkOrder.customer = selectedCustomer
                newWorkOrder.time = serviceTime
                newWorkOrder.notes = notes
                newWorkOrder.isCallback = isCallback
                newWorkOrder.workOrderNumber = Int16(nextWorkOrderNumber)

                // Assign tradesmen
                for tradesman in selectedTradesmen {
                    newWorkOrder.addToTradesmen(tradesman)
                    tradesman.addToWorkOrders(newWorkOrder)
                }

                // Assign tasks
                for task in tasks {
                    let newTask = Task(context: viewContext)
                    newTask.name = task.name
                    newTask.taskDescription = task.description
                    newTask.isComplete = task.isComplete
                    newWorkOrder.addToTasks(newTask)
                }

                // Serialize and assign materials
                let encoder = JSONEncoder()
                if let encodedMaterials = try? encoder.encode(selectedMaterials) {
                    newWorkOrder.materials = encodedMaterials
                }

                // Deduct selected materials from inventory
                for material in selectedMaterials {
                    if let inventoryItem = inventoryItems.first(where: { $0.name == material.name }) {
                        inventoryItem.quantity -= Int16(material.quantity)
                    }
                }

                // Save changes to Core Data
                try viewContext.save()

                // Recalculate points for gamification
                GamificationManager.shared.recalculatePoints(context: viewContext) {
                    DispatchQueue.main.async {
                        isSaving = false // Stop showing the spinner
                        presentationMode.wrappedValue.dismiss() // Close the view
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    isSaving = false // Stop showing the spinner
                }
                print("Error saving work order: \(error.localizedDescription)")
            }
        }
    }

    private func addTask() {
        guard !newTaskName.isEmpty && !newTaskDescription.isEmpty else { return }
        tasks.append(TaskItem(name: newTaskName, description: newTaskDescription, isComplete: false))
        newTaskName = ""
        newTaskDescription = ""
    }

    private func deleteTask(at index: Int) {
        tasks.remove(at: index)
    }
    
    private func showValidationError(message: String) {
        alertMessage = message
        isShowingIncompleteAlert = true
    }

    private func validateForm() -> Bool {
        if selectedCategory == nil {
            showValidationError(message: "Please select a category.")
            return false
        } else if selectedJob == nil {
            showValidationError(message: "Please select a job.")
            return false
        } else if workOrderDescription.isEmpty {
            showValidationError(message: "Please provide a work order description.")
            return false
        } else if selectedCustomer == nil {
            showValidationError(message: "Please assign a customer.")
            return false
        } else if tasks.isEmpty {
            showValidationError(message: "Please add at least one task.")
            return false
        } else if selectedMaterials.isEmpty {
            showValidationError(message: "Please select at least one material.")
            return false
        } else if selectedTradesmen.isEmpty {
            showValidationError(message: "Please assign at least one tradesman.")
            return false
        }

        return true
    }
}

// MARK: - TaskItem Model
struct TaskItem: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    var isComplete: Bool
}
