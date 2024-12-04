import SwiftUI
import CoreData

struct CreateInvoiceView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedWorkOrder: WorkOrder? = nil
    @State private var issueDate = Date()
    @State private var dueDate = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
    @State private var subtotal = 0.0
    @State private var taxPercentage = 4.0
    @State private var invoiceNotes = ""
    @State private var itemizedServices: [InvoiceItem] = []
    @State private var materials: [Material] = []  // Use 'Material' instead of 'MaterialItem'
    @State private var isCallback = false
    @State private var selectedPaymentMethod: PaymentMethod = .zelle  // Default payment method
    
    @FetchRequest(
        entity: WorkOrder.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \WorkOrder.date, ascending: false)]
    ) var workOrders: FetchedResults<WorkOrder>

    // Payment Methods
    enum PaymentMethod: String, CaseIterable, Identifiable {
        case applePay = "Apple Pay"
        case paypal = "PayPal"
        case zelle = "Zelle"
        case cash = "Cash"
        var id: String { self.rawValue }
    }

    // Calculate total amount dynamically
    var totalAmount: Double {
        let totalServiceCost = itemizedServices.reduce(0) { $0 + ($1.unitPrice * Double($1.quantity)) }
        let totalMaterialCost = materials.reduce(0) { $0 + ($1.price * Double($1.quantity)) }  // Updated to include quantity
        let combinedSubtotal = totalServiceCost + totalMaterialCost
        let taxAmount = (combinedSubtotal * taxPercentage) / 100
        return combinedSubtotal + taxAmount
    }

    var body: some View {
        Form {
            // Work Order Picker
            Section(header: Text("Select Work Order")) {
                Picker("Work Order", selection: $selectedWorkOrder) {
                    Text("Select a Work Order").tag(Optional<WorkOrder>.none)
                    ForEach(workOrders, id: \.self) { workOrder in
                        Text("\(workOrder.customer?.name ?? "Unknown Customer") - Work Order #\(workOrder.workOrderNumber)")
                            .tag(Optional(workOrder))
                    }
                }
                .onChange(of: selectedWorkOrder) { oldWorkOrder, newWorkOrder in
                    // Reset the totals when the "Select a Work Order" option is selected
                    if newWorkOrder == nil {
                        resetInvoice()
                    } else {
                        isCallback = newWorkOrder?.isCallback ?? false
                        populateMaterials(from: newWorkOrder)  // Auto-populate materials based on the selected work order
                    }
                }
            }

            // Is Callback Section
            Section(header: Text("Is this a Callback?")) {
                Toggle(isOn: $isCallback) {
                    Text("Yes / No")
                }
            }

            // Customer Payment Method Section
            Section(header: Text("Customer Payment Method")) {
                Picker("Payment Method", selection: $selectedPaymentMethod) {
                    ForEach(PaymentMethod.allCases) { method in
                        Text(method.rawValue).tag(method)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }

            // Itemized Services Section with Swipe-to-Delete
            Section(header: Text("Itemized Services")) {
                ForEach(itemizedServices.indices, id: \.self) { index in
                    HStack {
                        TextField("Description", text: $itemizedServices[index].description)
                        TextField("Price", value: $itemizedServices[index].unitPrice, format: .currency(code: "USD"))
                        TextField("Qty", value: $itemizedServices[index].quantity, format: .number)
                            .keyboardType(.numberPad)
                            .onChange(of: itemizedServices[index].quantity) { oldQuantity, newQuantity in
                                updateSubtotal()
                            }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            deleteItemizedService(at: index)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                Button("Add Service") {
                    addItemizedService()
                }
            }

            // Materials Section (Live Data Display)
            Section(header: Text("Materials")) {
                if materials.isEmpty {
                    Text("No materials for this work order")
                        .foregroundColor(.gray)
                } else {
                    ForEach(materials.indices, id: \.self) { index in
                        HStack {
                            Text(materials[index].name) // Use 'name' from 'Material'
                            Spacer()
                            
                            // Show individual price, quantity, and total cost
                            Text("Qty: \(materials[index].quantity)")
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            // Display total cost (price * quantity)
                            let totalCost = materials[index].price * Double(materials[index].quantity)
                            Text("$\(totalCost, specifier: "%.2f")")
                                .fontWeight(.bold)
                        }
                    }
                }
            }

            // Invoice Details Section
            Section(header: Text("Invoice Details")) {
                DatePicker("Issue Date", selection: $issueDate)
                DatePicker("Due Date", selection: $dueDate)
                Text("Subtotal: \(subtotal, specifier: "%.2f")")
                Text("Tax Percentage: \(taxPercentage, specifier: "%.2f")%")
                Text("Total: $\(totalAmount, specifier: "%.2f")")
                TextField("Notes", text: $invoiceNotes)
            }

            Button("Generate Invoice") {
                addInvoice()
                presentationMode.wrappedValue.dismiss()
            }
        }
        .navigationTitle("Create Invoice")
        .onAppear(perform: updateSubtotal)
    }

    // Dynamically calculate subtotal based on itemized services and materials
    private func updateSubtotal() {
        let totalServiceCost = itemizedServices.reduce(0) { $0 + ($1.unitPrice * Double($1.quantity)) }
        let totalMaterialCost = materials.reduce(0) { $0 + ($1.price * Double($1.quantity)) }  // Updated for 'price * quantity'
        self.subtotal = totalServiceCost + totalMaterialCost
    }

    // Populate materials based on the selected work order
    private func populateMaterials(from workOrder: WorkOrder?) {
        materials.removeAll() // Clear existing materials
        guard let workOrder = workOrder else { return }

        // Check if the work order is marked as completed
        if workOrder.status == "Completed" {
            // Decode the materials stored in Core Data
            if let materialData = workOrder.materials {
                print("Material data (as string): \(String(data: materialData, encoding: .utf8) ?? "Unreadable data")")
                let decoder = JSONDecoder()
                do {
                    let loadedMaterials = try decoder.decode([Material].self, from: materialData)  // Decode as 'Material'
                    self.materials = loadedMaterials
                    print("Loaded materials: \(self.materials)")
                } catch {
                    // If materials data exists but cannot be decoded
                    print("Failed to decode materials with error: \(error.localizedDescription)")
                }
            } else {
                // No materials data found
                print("No materials data found")
            }
        } else {
            // Work order is not completed
            print("Work order is not completed, skipping material population")
        }

        // Update subtotal after loading materials
        updateSubtotal()
    }

    private func resetInvoice() {
        // Reset materials, itemized services, and subtotal to 0 when no work order is selected
        materials.removeAll()
        itemizedServices.removeAll()
        subtotal = 0.0
    }

    private func addItemizedService() {
        itemizedServices.append(InvoiceItem(description: "", unitPrice: 0.0, quantity: 1))
        updateSubtotal()
    }

    private func deleteItemizedService(at index: Int) {
        itemizedServices.remove(at: index)
        updateSubtotal()
    }

    private func addInvoice() {
        guard let selectedWorkOrder = selectedWorkOrder else {
            print("No work order selected")
            return
        }

        let newInvoice = Invoice(context: viewContext)
        newInvoice.issueDate = issueDate
        newInvoice.dueDate = dueDate
        newInvoice.subtotal = subtotal
        newInvoice.taxPercentage = taxPercentage
        newInvoice.totalAmount = totalAmount
        newInvoice.invoiceNotes = invoiceNotes
        newInvoice.status = "Unpaid"
        newInvoice.workOrder = selectedWorkOrder
        newInvoice.isCallback = isCallback
        newInvoice.paymentMethod = selectedPaymentMethod.rawValue  // Save the selected payment method

        // Fetch the highest invoice number and assign a new one
        let fetchRequest: NSFetchRequest<Invoice> = Invoice.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Invoice.invoiceNumber, ascending: false)]
        fetchRequest.fetchLimit = 1

        do {
            // Fetch the highest existing invoice number
            let highestInvoice = try viewContext.fetch(fetchRequest).first
            let nextInvoiceNumber = (highestInvoice?.invoiceNumber ?? 0) + 1
            newInvoice.invoiceNumber = Int16(nextInvoiceNumber)  // Assign the next invoice number
            
            // Store itemized services
            newInvoice.itemizedServicesArray = itemizedServices
            
            // Assign materials to the invoice
            selectedWorkOrder.materialsArray = materials
            
            // Save the new invoice to the context
            try viewContext.save()
            print("Invoice #\(nextInvoiceNumber) saved successfully.")
        } catch {
            print("Failed to fetch or save invoice: \(error)")
        }
    }
}
// MARK: - InvoiceItem Model
struct InvoiceItem: Identifiable, Codable {
    var id = UUID()
    var description: String
    var unitPrice: Double
    var quantity: Int

    func dictionaryRepresentation() -> [String: Any] {
        return ["description": description, "unitPrice": unitPrice, "quantity": quantity]
    }
}
