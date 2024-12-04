import SwiftUI
import CoreData
import MessageUI

struct WorkOrderDetailView: View {
    @Environment(\.managedObjectContext) var viewContext
    @ObservedObject var workOrder: WorkOrder
    @Environment(\.presentationMode) var presentationMode
    
    @State var selectedPhotos: [UIImage] = []
    @State var isShowingPhotoPicker = false
    @State var selectedStatus: String? = nil
    @State var summary: String = ""
    @State var enlargedPhoto: UIImage? = nil
    @State var showingDeleteAlert = false
    @State var photoToDelete: UIImage? = nil
    @State var isShowingPhotosView = false
    @State var materialToDelete: Material? = nil
    @State var showingTechnicianSelection = false
    @State var selectedTechnicians: [Tradesmen] = []
    @Namespace var animation
    
    // Materials section states
    @State var materials: [Material] = []
    @State var newMaterialName: String = ""
    @State var newMaterialPrice: String = ""
    @State var newMaterialQuantity: String = ""
    @State var isAddingMaterial = false
    
    // Tasks section states
    @State var newTaskName: String = ""          // Holds the name of the new task
    @State var newTaskDescription: String = ""   // Holds the description of the new task
    @State var isAddingTask: Bool = false        // Tracks whether the Add Task form is displayed
    
    // New State variable for SMS sheet
    @State var showingMessageCompose = false
    @State var isShowingActionSheet = false // Control action sheet presentation
    
    
    // Tasks FetchRequest
    @FetchRequest var tasks: FetchedResults<Task>
    
    init(workOrder: WorkOrder) {
        self.workOrder = workOrder
        _tasks = FetchRequest<Task>(
            sortDescriptors: [],
            predicate: NSPredicate(format: "workOrder == %@", workOrder)
        )
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 30) {
                    
                    customerInformationSection
                    technicianInformationSection
                    callbackInformationSection
                    workOrderDetails
                    statusUpdateSection
                    tasksSection
                    summarySection
                    materialsSection
                    photosFolderSection
                    actionButtons
                }
                .padding()
                .onAppear {
                    selectedStatus = workOrder.status
                    summary = workOrder.summary ?? ""
                    loadMaterials()
                    printWorkOrderDetails()
                }
            }
            // SMS sheet presentation
            .sheet(isPresented: $showingMessageCompose) {
                if let phoneNumber = workOrder.customer?.phoneNumber {
                    MessageComposeView(recipients: [phoneNumber], body: buildMessageText(for: workOrder))
                }
            }
            .sheet(isPresented: $isShowingPhotoPicker) {
                PhotoPicker(photos: $selectedPhotos, onSave: savePhotosToWorkOrder)
            }
            .navigationTitle("Work Order Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Text("Work Order Details")
                        Spacer()
                        Text("#\(workOrder.workOrderNumber)")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }
            }
            .alert(isPresented: $showingDeleteAlert) {
                Alert(
                    title: Text("Delete Material"),
                    message: Text("Are you sure you want to delete this material?"),
                    primaryButton: .destructive(Text("Delete")) {
                        if let material = materialToDelete {
                            deleteMaterial(material)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
            
            if enlargedPhoto != nil {
                EnlargedPhotoView(enlargedPhoto: $enlargedPhoto, animation: animation)
            }
        }
        .sheet(isPresented: $isShowingPhotosView) {
            PhotosView(workOrder: workOrder)
        }
        .sheet(isPresented: $showingTechnicianSelection) {
            TechnicianSelectionView(selectedTechnicians: $selectedTechnicians, onSave: assignTechnicians)
        }
    }
    // MARK: - Add New Tasks
    func addTask() {
        guard !newTaskName.isEmpty else { return }
        
        // Create a new Task in the context
        let newTask = Task(context: viewContext)
        newTask.name = newTaskName
        newTask.taskDescription = newTaskDescription
        newTask.isComplete = false
        
        // Associate the task with the current work order
        newTask.workOrder = workOrder
        
        do {
            // Save the context to persist the new task
            try viewContext.save()
            
            // Clear the input fields after saving
            newTaskName = ""
            newTaskDescription = ""
            isAddingTask = false
        } catch {
            print("Failed to save task: \(error)")
        }
    }
    // MARK: - Build SMS Message Content
    private func buildMessageText(for workOrder: WorkOrder) -> String {
        var message = "Hello, your work order (#\(workOrder.workOrderNumber)) for \(workOrder.category ?? "N/A")"
        if let date = workOrder.date {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            message += " is scheduled for \(dateFormatter.string(from: date))."
        }
        message += " Please confirm by replying to this message. Thank you!"
        return message
    }
    
    // MARK: - MessageComposeView for SMS
    struct MessageComposeView: UIViewControllerRepresentable {
        var recipients: [String]
        var body: String
        
        class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
            var parent: MessageComposeView
            
            init(_ parent: MessageComposeView) {
                self.parent = parent
            }
            
            func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
                controller.dismiss(animated: true)
            }
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }
        
        func makeUIViewController(context: Context) -> MFMessageComposeViewController {
            let controller = MFMessageComposeViewController()
            controller.recipients = recipients
            controller.body = body
            controller.messageComposeDelegate = context.coordinator
            return controller
        }
        
        func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}
    }
    // MARK: - Technician Information Section
    var technicianInformationSection: some View {
        VStack(spacing: 12) {  // Reduce spacing for a more compact design
            Text("Assigned Technician")
                .font(.headline)
                .padding(.bottom, 6) // Tighter padding for the header
                .multilineTextAlignment(.center)
            
            if let tradesmenSet = workOrder.tradesmen as? Set<Tradesmen>, !tradesmenSet.isEmpty {
                // Convert tradesmen names to a string
                let tradesmenNames = tradesmenSet.compactMap { $0.name }.joined(separator: ", ")
                
                // Display names in a sleek container
                Text(tradesmenNames)
                    .font(.body)
                    .foregroundColor(.blue)
                    .padding(10) // Uniform padding inside the container
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.systemGray6)) // Softer background for a modern feel
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2) // Light shadow for a more subtle effect
                    .multilineTextAlignment(.center)
                    .onTapGesture {
                        showingTechnicianSelection = true // Show technician selection
                    }
            } else {
                Text("No technician assigned")
                    .font(.body)
                    .foregroundColor(.red)
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .multilineTextAlignment(.center)
                    .onTapGesture {
                        showingTechnicianSelection = true // Show technician selection
                    }
            }
        }
        .padding(.horizontal, 16) // Horizontal padding to match modern UI conventions
        .padding(.vertical, 12) // Reduce vertical padding for compactness
        .background(Color.clear) // Keeps the background clean
        .onAppear {
            // Debug: Print the assigned tradesmen when the view appears
            if let tradesmenSet = workOrder.tradesmen as? Set<Tradesmen>, !tradesmenSet.isEmpty {
                let tradesmenNames = tradesmenSet.compactMap { $0.name }.joined(separator: ", ")
                print("Assigned Tradesmen: \(tradesmenNames)")
            } else {
                print("No technician assigned")
            }
        }
    }
    // MARK: - Technician Assignment Function
    func assignTechnicians() {
        // Update the workOrder's tradesmen relationship with selectedTechnicians
        workOrder.tradesmen = NSSet(array: selectedTechnicians)
        
        do {
            try viewContext.save() // Save changes to Core Data
            print("Technicians assigned successfully.")
            showingTechnicianSelection = false // Dismiss the sheet after saving successfully
        } catch {
            print("Failed to assign technicians: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Technician Selection View
    struct TechnicianSelectionView: View {
        @Binding var selectedTechnicians: [Tradesmen]
        var onSave: () -> Void
        @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Tradesmen.name, ascending: true)]) var allTechnicians: FetchedResults<Tradesmen>
        
        var body: some View {
            VStack {
                Text("Select Technicians")
                    .font(.headline)
                    .padding()
                
                List(allTechnicians, id: \.self) { technician in
                    HStack {
                        Text(technician.name ?? "Unknown")
                        Spacer()
                        if selectedTechnicians.contains(technician) {
                            Image(systemName: "checkmark")
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toggleSelection(for: technician)
                    }
                }
                
                Button(action: onSave) {
                    Text("Save")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding()
            }
        }
        
        private func toggleSelection(for technician: Tradesmen) {
            if let index = selectedTechnicians.firstIndex(of: technician) {
                selectedTechnicians.remove(at: index)
            } else {
                selectedTechnicians.append(technician)
            }
        }
    }
    
    // MARK: - Print WorkOrder Details for Debugging
    func printWorkOrderDetails() {
        print("---- Work Order Details ----")
        print("Work Order Number: \(workOrder.workOrderNumber)")
        print("Customer Name: \(workOrder.customer?.name ?? "No customer")")
        print("Status: \(workOrder.status ?? "No status")")
        print("Summary: \(workOrder.summary ?? "No summary")")
        
        // Print associated tradesmen
        if let tradesmenSet = workOrder.tradesmen as? Set<Tradesmen>, !tradesmenSet.isEmpty {
            let tradesmenNames = tradesmenSet.compactMap { $0.name }.joined(separator: ", ")
            print("Assigned Tradesmen: \(tradesmenNames)")
        } else {
            print("No technician assigned")
        }
        
        // Print associated tasks
        if tasks.isEmpty {
            print("No tasks assigned to this work order.")
        } else {
            print("Tasks assigned to this work order:")
            for task in tasks {
                print(" - \(task.name ?? "Unnamed task")")
            }
        }
        
        print("-----------------------------")
    }
    
    // MARK: - Materials Section
    var materialsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Materials purchased while on site")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(materials) { material in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(material.name)
                                .font(.headline)
                                .foregroundColor(.black)
                                .multilineTextAlignment(.leading)
                                .lineLimit(nil)
                            Text("$\(material.price, specifier: "%.2f")")
                                .font(.subheadline)
                                .foregroundColor(.black)
                            Text("Qty: \(material.quantity)")
                                .font(.subheadline)
                                .foregroundColor(.black)
                        }
                        .padding()
                        .frame(width: 200, height: 120)
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .onLongPressGesture {
                            materialToDelete = material
                            showingDeleteAlert = true
                        }
                    }
                    Button(action: {
                        isAddingMaterial = true
                    }) {
                        VStack {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.blue)
                        }
                        .padding()
                        .frame(width: 200, height: 120)
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                    }
                }
                .padding(.horizontal)
            }
            
            if isAddingMaterial {
                VStack(alignment: .leading, spacing: 10) {
                    TextField("Material Name", text: $newMaterialName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("Material Price", text: $newMaterialPrice)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("Material Quantity", text: $newMaterialQuantity)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    HStack {
                        Button(action: {
                            addNewMaterial()
                        }) {
                            Text("Save")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(8)
                        }
                        Button(action: {
                            isAddingMaterial = false
                        }) {
                            Text("Cancel")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 5)
            }
        }
        .padding(.vertical)
    }
    
    // MARK: - Add New Material
    func addNewMaterial() {
        guard !newMaterialName.isEmpty,
              let price = Double(newMaterialPrice),
              let quantity = Int(newMaterialQuantity) else { return }
        let newMaterial = Material(name: newMaterialName, price: price, quantity: quantity)
        materials.append(newMaterial)
        newMaterialName = ""
        newMaterialPrice = ""
        newMaterialQuantity = ""
        isAddingMaterial = false
        saveMaterials()
    }
    
    func deleteMaterial(_ material: Material) {
        materials.removeAll { $0.id == material.id }
        saveMaterials()
    }
    
    // MARK: - Save Materials to Core Data
    func saveMaterials() {
        let encoder = JSONEncoder()
        if let encodedMaterials = try? encoder.encode(materials) {
            workOrder.materials = encodedMaterials
        }
        do {
            try viewContext.save()
        } catch {
            print("Failed to save materials: \(error)")
        }
    }
    
    // MARK: - Load Materials from Core Data
    func loadMaterials() {
        if let data = workOrder.materials {
            let decoder = JSONDecoder()
            materials = (try? decoder.decode([Material].self, from: data)) ?? []
        }
    }
    
    // MARK: - Save Photos to WorkOrder with Compression
    func savePhotosToWorkOrder() {
        var currentPhotos = workOrder.photos as? [Data] ?? []
        let compressedPhotos = selectedPhotos.compactMap { $0.jpegData(compressionQuality: 0.5) }
        currentPhotos.append(contentsOf: compressedPhotos)
        workOrder.photos = currentPhotos as NSArray
        do {
            try viewContext.save()
        } catch {
            print("Failed to save photos: \(error)")
        }
    }
    
    // MARK: - Delete Photo
    func deletePhoto(_ photo: UIImage) {
        selectedPhotos.removeAll { $0 == photo }
        var currentPhotos = workOrder.photos as? [Data] ?? []
        if let photoData = photo.jpegData(compressionQuality: 0.5) {
            currentPhotos.removeAll { $0 == photoData }
        }
        workOrder.photos = currentPhotos as NSArray
        do {
            try viewContext.save()
        } catch {
            print("Failed to delete photo: \(error)")
        }
    }
    
    // MARK: - Save Context
    func saveContext() {
        do {
            viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            try viewContext.save()
        } catch {
            print("Error saving context: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Submit Work Order
    func submitWorkOrder() {
        if let selectedStatus = selectedStatus {
            workOrder.status = selectedStatus
        }

        workOrder.summary = summary
        savePhotosToWorkOrder()
        saveMaterials()

        // Add logic for job completion and gamification
        if selectedStatus == "Completed" {
            if let tradesmenSet = workOrder.tradesmen as? Set<Tradesmen> {
                for tradesman in tradesmenSet {
                    // Update job completion
                    completeJob(for: tradesman, wasSuccessful: true, context: viewContext)

                    // Add points
                    let tradesmanName = tradesman.name ?? "Unknown"
                    GamificationManager.shared.addPoints(to: tradesmanName, points: 50, context: viewContext) // Pass context here

                    // Increment completedJobs
                    tradesman.completedJobs += 1

                    // Assign badges
                    if tradesman.completedJobs == 1 {
                        GamificationManager.shared.earnBadge(for: tradesmanName, badge: "First Job Completed", context: viewContext) // Pass context here
                    } else if tradesman.completedJobs % 10 == 0 {
                        GamificationManager.shared.earnBadge(for: tradesmanName, badge: "10 Jobs Milestone", context: viewContext) // Pass context here
                    }
                }
            }
        }

        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Failed to save work order: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Complete Job
    func completeJob(for tradesman: Tradesmen, wasSuccessful: Bool, context: NSManagedObjectContext) {
        TradesmenManager.shared.addPoints(to: tradesman, points: 50, context: context)  // Pass context here
        TradesmenManager.shared.updateJobCompletionStreak(for: tradesman, isSuccessful: wasSuccessful, context: context)
    }
}
