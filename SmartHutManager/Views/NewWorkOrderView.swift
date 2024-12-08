import SwiftUI
import CoreData

struct NewWorkOrderView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode

    // Work Order Details
    @State private var category: String? = nil
    let categories = [
        "Accent Wall", "Camera Installation", "Drywall Repair", "Electrical", "Furniture Assembly",
        "General Handyman", "Home Theater Installation", "Lighting", "Painting", "Picture Hanging",
        "Plumbing", "Pressure Washing", "TV Mounting"
    ]

    @State private var workOrderDescription = ""
    @State private var status = "Open"
    @State private var selectedCustomer: Customer?
    @State private var isShowingCustomerList = false
    @State private var isShowingAddCustomerView = false
    @State private var serviceTime = Date() // Time of service
    @State private var notes = "" // Customer preferences
    @State private var isCallback = false
    @State private var selectedJob: String? = nil

    @State private var tasks: [TaskItem] = [] // Task items
    @State private var newTaskName = ""
    @State private var newTaskDescription = ""

    @State private var isShowingIncompleteAlert = false
    @State private var alertMessage = ""
    
    var selectedDate: Date // Passed selected date from JobSchedulerView
    @State private var serviceDate: Date // Initialize serviceDate with selectedDate

    init(selectedDate: Date) {
        self.selectedDate = selectedDate
        self._serviceDate = State(initialValue: selectedDate) // Pre-fill with selected date
    }

    // Fetch tradesmen from Core Data
    @FetchRequest(entity: Tradesmen.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Tradesmen.name, ascending: true)])
    var fetchedTradesmen: FetchedResults<Tradesmen>
    
    @State private var selectedTradesmen: Set<Tradesmen> = []
    
    // Fetch customers from Core Data
    @FetchRequest(entity: Customer.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Customer.name, ascending: true)])
    var customers: FetchedResults<Customer>
    
    // Job options related to each category
    let jobOptions: [String: [(job: String, description: String, price: Double)]] = [
                "Accent Wall": [
                    ("Install Shiplap", "Install a shiplap accent wall", 500),
                    ("Paint Accent Wall", "Paint an accent wall with up to 3 colors", 250)
                ],
                "Camera Installation": [
                    ("Install Outdoor Camera", "Install and configure outdoor security cameras", 150),
                    ("Install Indoor Camera", "Install and configure indoor security cameras", 100)
                ],
                "Drywall Repair": [
                    ("Patch Small Hole", "Repair a small hole in drywall", 75),
                    ("Patch Large Hole", "Repair a large hole in drywall", 150)
                ],
                "Electrical": [
                    ("Install Light Fixture", "Install a new light fixture", 200),
                    ("Replace Outlet", "Replace existing electrical outlet", 75)
                ],
                "Furniture Assembly": [
                    ("Assemble Table", "Assemble a standard-sized table", 100),
                    ("Assemble Bookshelf", "Assemble a medium-sized bookshelf", 80)
                ],
                "General Handyman": [
                    ("Fix Leaky Faucet", "Fix a leaky faucet", 100),
                    ("Install Door Handle", "Replace or install a door handle", 50)
                ],
                "Home Theater Installation": [
                    ("Install Surround Sound", "Install a full surround sound system", 300),
                    ("Setup Home Theater", "Configure and setup home theater equipment", 400)
                ],
                "Lighting": [
                    ("Install Ceiling Fan", "Install and wire a ceiling fan", 150),
                    ("Install Dimmer Switch", "Install a dimmer switch", 100)
                ],
                "Painting": [
                    ("Paint Room", "Paint a standard-sized room", 500),
                    ("Touch Up Painting", "Small touch-up painting", 150)
                ],
                "Picture Hanging": [
                    ("Hang Picture Frames", "Hang picture frames (up to 10)", 100),
                    ("Install Gallery Wall", "Install a gallery wall", 200)
                ],
                "Plumbing": [
                    ("Fix Leaky Pipe", "Repair a leaky pipe", 200),
                    ("Unclog Drain", "Unclog a drain", 150)
                ],
                "Pressure Washing": [
                    ("Pressure Wash Driveway", "Pressure wash driveway", 250),
                    ("Pressure Wash Deck", "Pressure wash deck", 300)
                ],
                "TV Mounting": [
                    ("Mount 32-50\" TV", "Mount and secure TV between 32\" and 50\"", 100),
                    ("Mount 50-70\" TV", "Mount and secure TV between 50\" and 70\"", 150)
                ]
            ]
    
    var body: some View {
        NavigationView {
            Form {
                // Assign Customer and Create New Customer sections
                Section(header: Text("Assign Customer")) {
                    // Add New Customer Button
                    Button(action: { isShowingAddCustomerView.toggle() }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                            Text("Add New Customer")
                        }
                    }
                    
                    // Select Customer Button
                    Button(action: { isShowingCustomerList.toggle() }) {
                        HStack {
                            Text(selectedCustomer?.name ?? "Select Customer")
                            Spacer()
                            Image(systemName: "chevron.right").foregroundColor(.gray)
                        }
                    }
                }
                
                // Is this a Callback Section
                Section(header: Text("Is this a Callback?")) {
                    Toggle(isOn: $isCallback) {
                        Text(isCallback ? "Yes" : "No")
                            .foregroundColor(isCallback ? .green : .red)
                    }
                }
                
                // Work Order Details Section
                Section(header: Text("Work Order Details")) {
                    // Category Picker
                    Picker("Category", selection: $category) {
                        Text("Select a Category").tag(String?.none)
                        ForEach(categories, id: \.self) {
                            Text($0).tag(String?.some($0))
                        }
                    }
                    // Use zero-parameter closure to reset selectedJob and workOrderDescription
                    .onChange(of: category) {
                        selectedJob = nil
                        workOrderDescription = ""
                    }
                    
                    // Job Picker (depends on selected category)
                    Picker("Select Job", selection: $selectedJob) {
                        if let category = category, let jobs = jobOptions[category] {
                            ForEach(jobs, id: \.job) { job in
                                Text(job.job).tag(String?.some(job.job))
                            }
                        } else {
                            Text("Select job category first").tag(String?.none)
                        }
                    }
                    // Use zero-parameter closure to update workOrderDescription based on selectedJob
                    .onChange(of: selectedJob) {
                        if let category = category, let jobs = jobOptions[category] {
                            if let job = jobs.first(where: { $0.job == selectedJob }) {
                                workOrderDescription = job.description
                            }
                        }
                    }
                    
                    // Date of Service Picker
                    DatePicker("Date of Service", selection: $serviceDate, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                        .padding(.vertical, 10)
                    
                    // Time of Service Picker
                    DatePicker("Time of Service", selection: $serviceTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(CompactDatePickerStyle())
                        .padding(.vertical, 10)
                    
                    // Customer Preferences (notes) field
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
                
                // Work Order Description Section (multiline)
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
                
                // Task Section with Swipe-to-Delete
                Section(header: Text("Tasks")) {
                    ForEach(tasks.indices, id: \.self) { index in
                        VStack(alignment: .leading) {
                            Text(tasks[index].name)
                                .font(.headline)
                            Text(tasks[index].description)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 5)
                        .swipeActions {
                            Button(role: .destructive) {
                                deleteTask(at: index)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    
                    // Add new task section
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
                
                // Tradesmen selection section
                Section(header: Text("Assign Technician")) {
                    List(fetchedTradesmen, id: \.self) { tradesman in
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
                
                // Save Button Section
                Section {
                    Button(action: {
                        if validateForm() {
                            addWorkOrder()
                        }
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle")
                            Text("Save Work Order")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(validateForm() ? Color.green : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!validateForm())
                    .alert(isPresented: $isShowingIncompleteAlert) {
                        Alert(
                            title: Text("Incomplete Form"),
                            message: Text(alertMessage),
                            dismissButton: .default(Text("OK"))
                        )
                    }
                }
            }
            .navigationTitle("Create Work Order")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
            }
            .sheet(isPresented: $isShowingCustomerList) {
                CustomerPickerView(selectedCustomer: $selectedCustomer)
            }
            .sheet(isPresented: $isShowingAddCustomerView) {
                AddCustomerView(onCustomerCreated: { newCustomer in selectedCustomer = newCustomer })
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }
    
    // Function to add a task
    private func addTask() {
        guard !newTaskName.isEmpty && !newTaskDescription.isEmpty else { return }
        let task = TaskItem(name: newTaskName, description: newTaskDescription, isComplete: false)
        tasks.append(task)
        newTaskName = ""
        newTaskDescription = ""
    }
    
    // Function to delete a task
    private func deleteTask(at index: Int) {
        let removedTask = tasks.remove(at: index)
        print("Deleted task: \(removedTask.name)")

        // Remove points for all assigned tradesmen if a task is deleted
        for tradesman in selectedTradesmen {
            GamificationManager.shared.removeWorkOrderPoints(from: tradesman.name ?? "", context: viewContext)
        }
    }
    
    // Validate the form and show an alert message if incomplete
    private func validateForm() -> Bool {
        if category == nil {
            alertMessage = "Please select a category."
            return false
        } else if workOrderDescription.isEmpty {
            alertMessage = "Please provide a work order description."
            return false
        } else if selectedCustomer == nil {
            alertMessage = "Please assign a customer."
            return false
        } else if tasks.isEmpty {
            alertMessage = "Please add at least one task."
            return false
        } else if selectedTradesmen.isEmpty {
            alertMessage = "Please assign at least one tradesman."
            return false
        }
        return true
    }
    
    // Add the work order to Core Data
    private func addWorkOrder() {
        let fetchRequest: NSFetchRequest<WorkOrder> = NSFetchRequest(entityName: "WorkOrder")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \WorkOrder.workOrderNumber, ascending: false)]
        fetchRequest.fetchLimit = 1

        do {
            let highestWorkOrder = try viewContext.fetch(fetchRequest).first
            let nextWorkOrderNumber = (highestWorkOrder?.workOrderNumber ?? 0) + 1

            let newWorkOrder = WorkOrder(context: viewContext)
            newWorkOrder.category = category
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

            try viewContext.save()

            // Recalculate points
            GamificationManager.shared.recalculatePoints(context: viewContext) {
                // Reload leaderboard view after recalculation
            }

            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error saving work order: \(error.localizedDescription)")
        }
    }
    
    // Local task model to manage the task items before saving them to Core Data
    struct TaskItem: Identifiable {
        var id = UUID()
        var name: String
        var description: String
        var isComplete: Bool
    }
}
