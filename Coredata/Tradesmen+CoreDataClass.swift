import Foundation
import CoreData

@objc(Tradesmen)
public class Tradesmen: NSManagedObject {
    // Computed property to handle badges as an array using BadgesTransformer
    var badgesArray: [String] {
        get {
            let transformer = BadgesTransformer()
            return transformer.reverseTransformedValue(badges) as? [String] ?? []
        }
        set {
            let transformer = BadgesTransformer()
            badges = transformer.transformedValue(newValue) as? [String]
        }
    }
}
