//
//  UsageRecord+CoreDataProperties.swift
//  SmartHutManager
//
//  Created by Darius Ogletree on 1/2/25.
//
//

import Foundation
import CoreData


extension UsageRecord {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UsageRecord> {
        return NSFetchRequest<UsageRecord>(entityName: "UsageRecord")
    }

    @NSManaged public var date: Date?
    @NSManaged public var quantityUsed: Int16
    @NSManaged public var inventory: Inventory?

}

extension UsageRecord : Identifiable {

}
