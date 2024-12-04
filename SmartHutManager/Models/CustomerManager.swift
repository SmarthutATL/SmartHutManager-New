import CoreData

class CustomerManager {
    static let shared = CustomerManager()
    
    private init() {}
    
    // Function to create a new WorkOrder
    func createWorkOrder(
        category: String,
        description: String,
        date: Date,
        photos: [String],
        status: String,
        in context: NSManagedObjectContext
    ) -> WorkOrder {
        let workOrder = WorkOrder(context: context)
        workOrder.category = category
        workOrder.workOrderDescription = description // Assuming Core Data property is named `workOrderDescription`
        workOrder.date = date
        workOrder.photos = photos as [String] as NSArray
        workOrder.status = status
        
        return workOrder
    }
    
    // Function to create a new Customer
    func createCustomer(
        name: String,
        email: String,
        phoneNumber: String,
        workOrders: [WorkOrder],
        in context: NSManagedObjectContext
    ) -> Customer {
        let customer = Customer(context: context)
        customer.name = name
        customer.email = email
        customer.phoneNumber = phoneNumber
        
        for workOrder in workOrders {
            customer.addToWorkOrders(workOrder)
        }
        
        return customer
    }
}

