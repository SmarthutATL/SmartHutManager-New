//
//  Tradesmen+CoreDataProperties.swift
//  SmartHutManager
//
//  Created by Darius Ogletree on 10/16/24.
//
//

import Foundation
import CoreData


extension Tradesmen {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Tradesmen> {
        return NSFetchRequest<Tradesmen>(entityName: "Tradesmen")
    }

    @NSManaged public var name: String?
    @NSManaged public var jobTitle: String?
    @NSManaged public var phoneNumber: String?
    @NSManaged public var address: String?
    @NSManaged public var workOrders: NSSet?
    @NSManaged public var email: String?
    @NSManaged public var points: Int32
    @NSManaged public var badges: [String]?
    @NSManaged public var jobCompletionStreak: Int32
    @NSManaged public var completedJobs: Int16
    @NSManaged public var workOrderPoints: Int32

}

// MARK: Generated accessors for workOrders
extension Tradesmen {

    @objc(addWorkOrdersObject:)
    @NSManaged public func addToWorkOrders(_ value: WorkOrder)

    @objc(removeWorkOrdersObject:)
    @NSManaged public func removeFromWorkOrders(_ value: WorkOrder)

    @objc(addWorkOrders:)
    @NSManaged public func addToWorkOrders(_ values: NSSet)

    @objc(removeWorkOrders:)
    @NSManaged public func removeFromWorkOrders(_ values: NSSet)

}

extension Tradesmen : Identifiable {

}
