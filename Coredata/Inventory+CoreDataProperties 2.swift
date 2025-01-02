//
//  Inventory+CoreDataProperties.swift
//  SmartHutManager
//
//  Created by Darius Ogletree on 12/31/24.
//
//

import Foundation
import CoreData


extension Inventory {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Inventory> {
        return NSFetchRequest<Inventory>(entityName: "Inventory")
    }

    @NSManaged public var name: String?
    @NSManaged public var price: Double
    @NSManaged public var quantity: Int16
    @NSManaged public var tradesmen: Tradesmen?
    @NSManaged public var lowStockThreshold: Int16
    @NSManaged public var highStockThreshold: Int16
    @NSManaged public var date: Date?
    @NSManaged public var usageHistory: Set<UsageRecord>
}

extension Inventory : Identifiable {

}
