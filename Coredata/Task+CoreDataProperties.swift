//
//  Task+CoreDataProperties.swift
//  SmartHutManager
//
//  Created by Darius Ogletree on 1/12/25.
//
//

import Foundation
import CoreData


extension Task {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Task> {
        return NSFetchRequest<Task>(entityName: "TaskEntity")
    }

    @NSManaged public var isComplete: Bool
    @NSManaged public var name: String?
    @NSManaged public var taskDescription: String?
    @NSManaged public var workOrder: WorkOrder?

}

extension Task : Identifiable {

}
