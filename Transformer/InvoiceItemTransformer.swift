import Foundation
import CoreData

@objc(InvoiceItemTransformer)
class InvoiceItemTransformer: ValueTransformer {
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }

    override class func transformedValueClass() -> AnyClass {
        return NSData.self
    }

    override func transformedValue(_ value: Any?) -> Any? {
        guard let items = value as? [InvoiceItem] else { return nil }
        let encoder = JSONEncoder()
        return try? encoder.encode(items)
    }

    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode([InvoiceItem].self, from: data)
    }
}
