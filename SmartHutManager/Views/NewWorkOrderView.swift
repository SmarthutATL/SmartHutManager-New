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
    @State private var serviceTime = Date() // Time of service
    @State private var notes = "" // Customer preferences
    @State private var isCallback = false

    @State private var tasks: [TaskItem] = [] // Task items
    @State private var newTaskName = ""
    @State private var newTaskDescription = ""
    @State private var isShowingIncompleteAlert = false
    @State private var alertMessage = ""
    @State private var isSaving = false
    
    var selectedDate: Date // Passed selected date from JobSchedulerView
    @State private var serviceDate: Date // Initialize serviceDate with selectedDate

    init(selectedDate: Date) {
        self.selectedDate = selectedDate
        self._serviceDate = State(initialValue: selectedDate) // Pre-fill with selected date
    }

    // Fetch categories dynamically from CoreData
    @FetchRequest(
        entity: JobCategoryEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \JobCategoryEntity.name, ascending: true)]
    ) var categories: FetchedResults<JobCategoryEntity>

    // Fetch tradesmen from Core Data
    @FetchRequest(
        entity: Tradesmen.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Tradesmen.name, ascending: true)]
    ) var fetchedTradesmen: FetchedResults<Tradesmen>
    
    @State private var selectedTradesmen: Set<Tradesmen> = []
    
    // Fetch customers from Core Data
    @FetchRequest(
        entity: Customer.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Customer.name, ascending: true)]
    ) var customers: FetchedResults<Customer>
  
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
                                   Picker("Category", selection: $selectedCategory) {
                                       if categories.isEmpty {
                                           Text("No categories available").foregroundColor(.gray)
                                       } else {
                                           ForEach(categories, id: \.self) { category in
                                               Text(category.name ?? "Unknown Category").tag(category as JobCategoryEntity?)
                                           }
                                       }
                                   }
                                   .onChange(of: selectedCategory) { newValue, _ in
                                       selectedJob = nil
                                       workOrderDescription = ""
                                   }
                                   
                                   // Job Picker (depends on selected category)
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
    
    private func fetchJobsForCategory(_ category: JobCategoryEntity) -> [JobOptionEntity] {
            let fetchRequest: NSFetchRequest<JobOptionEntity> = JobOptionEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "category == %@", category)
            return (try? viewContext.fetch(fetchRequest)) ?? []
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
        } else if selectedTradesmen.isEmpty {
            showValidationError(message: "Please assign at least one tradesman.")
            return false
        }

        return true
    }

    private func showValidationError(message: String) {
        alertMessage = message
        isShowingIncompleteAlert = true
    }
    
    // Add the work order to Core Data
    private func addWorkOrder() {
        isSaving = true // Start showing the spinner
        
        DispatchQueue.global(qos: .userInitiated).async {
            let fetchRequest: NSFetchRequest<WorkOrder> = NSFetchRequest(entityName: "WorkOrder")
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \WorkOrder.workOrderNumber, ascending: false)]
            fetchRequest.fetchLimit = 1
            
            do {
                let highestWorkOrder = try viewContext.fetch(fetchRequest).first
                let nextWorkOrderNumber = (highestWorkOrder?.workOrderNumber ?? 0) + 1
                
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
                
                try viewContext.save()
                
                // Recalculate points
                GamificationManager.shared.recalculatePoints(context: viewContext) {
                    DispatchQueue.main.async {
                        isSaving = false // Stop showing the spinner
                        presentationMode.wrappedValue.dismiss() // Close the view
                    }
                }
                
                DispatchQueue.main.async {
                    isSaving = false // Stop showing the spinner
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                DispatchQueue.main.async {
                    isSaving = false // Stop showing the spinner
                }
                print("Error saving work order: \(error.localizedDescription)")
            }
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
