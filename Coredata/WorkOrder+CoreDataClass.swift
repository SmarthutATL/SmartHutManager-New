//
//  WorkOrder+CoreDataClass.swift
//  SmartHutManager
//
//  Created by Darius Ogletree on 10/16/24.
//
//

import Foundation
import CoreData

@objc(WorkOrder)
public class WorkOrder: NSManagedObject {
    // Computed property to handle the materials as an array of Material
    var materialsArray: [Material] {
        get {
            let transformer = MaterialItemTransformer() // Reuse the transformer, now for Material
            return transformer.reverseTransformedValue(materials) as? [Material] ?? []
        }
        set {
            let transformer = MaterialItemTransformer()
            materials = transformer.transformedValue(newValue) as? Data
        }
    }
}
