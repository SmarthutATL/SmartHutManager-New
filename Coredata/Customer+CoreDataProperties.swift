//
//  Customer+CoreDataProperties.swift
//  SmartHutManager
//
//  Created by Darius Ogletree on 10/9/24.
//
//

import Foundation
import CoreData


extension Customer {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SmartHutManager.Customer> {
        return NSFetchRequest<SmartHutManager.Customer>(entityName: "Customer")
    }

    @NSManaged public var email: String?
    @NSManaged public var name: String?
    @NSManaged public var phoneNumber: String?
    @NSManaged public var address: String?
    @NSManaged public var workOrders: NSSet?
    
}

// MARK: Generated accessors for workOrders
extension Customer {

    @objc(addWorkOrdersObject:)
    @NSManaged public func addToWorkOrders(_ value: WorkOrder)

    @objc(removeWorkOrdersObject:)
    @NSManaged public func removeFromWorkOrders(_ value: WorkOrder)

    @objc(addWorkOrders:)
    @NSManaged public func addToWorkOrders(_ values: NSSet)

    @objc(removeWorkOrders:)
    @NSManaged public func removeFromWorkOrders(_ values: NSSet)

}

extension Customer : Identifiable {

}
