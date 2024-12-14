//
//  WorkOrder+CoreDataProperties.swift
//  SmartHutManager
//
//  Created by Darius Ogletree on 10/16/24.
//
//

import Foundation
import CoreData


extension WorkOrder {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WorkOrder> {
        return NSFetchRequest<WorkOrder>(entityName: "WorkOrder")
    }

    @NSManaged public var category: String?
    @NSManaged public var date: Date?
    @NSManaged public var isCallback: Bool
    @NSManaged public var materials: Data?
    @NSManaged public var notes: String?
    @NSManaged public var photos: NSArray?
    @NSManaged public var signature: Data?
    @NSManaged public var status: String?
    @NSManaged public var summary: String?
    @NSManaged public var technician: String?
    @NSManaged public var time: Date?
    @NSManaged public var workOrderDescription: String?
    @NSManaged public var workOrderNumber: Int16
    @NSManaged public var customer: Customer?
    @NSManaged public var invoice: Invoice?
    @NSManaged public var tasks: NSSet?
    @NSManaged public var tradesmen: NSSet?
    @NSManaged public var job: JobOptionEntity?

}

// MARK: Generated accessors for tasks
extension WorkOrder {

    @objc(addTasksObject:)
    @NSManaged public func addToTasks(_ value: Task)

    @objc(removeTasksObject:)
    @NSManaged public func removeFromTasks(_ value: Task)

    @objc(addTasks:)
    @NSManaged public func addToTasks(_ values: NSSet)

    @objc(removeTasks:)
    @NSManaged public func removeFromTasks(_ values: NSSet)

}

// MARK: Generated accessors for tradesmen
extension WorkOrder {

    @objc(addTradesmenObject:)
    @NSManaged public func addToTradesmen(_ value: Tradesmen)

    @objc(removeTradesmenObject:)
    @NSManaged public func removeFromTradesmen(_ value: Tradesmen)

    @objc(addTradesmen:)
    @NSManaged public func addToTradesmen(_ values: NSSet)

    @objc(removeTradesmen:)
    @NSManaged public func removeFromTradesmen(_ values: NSSet)

}

extension WorkOrder : Identifiable {

}
