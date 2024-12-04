import Foundation
import CoreData

@objc(Invoice)
public class Invoice: NSManagedObject {
    
    // Computed property to handle the itemizedServices as an array of InvoiceItem
    var itemizedServicesArray: [InvoiceItem] {
        get {
            // Using the ValueTransformer to decode itemizedServices data
            let transformer = InvoiceItemTransformer()
            return transformer.reverseTransformedValue(itemizedServices) as? [InvoiceItem] ?? []
        }
        set {
            // Encode the array of InvoiceItem into Data and store it
            let transformer = InvoiceItemTransformer()
            itemizedServices = transformer.transformedValue(newValue) as? Data
        }
    }
}
