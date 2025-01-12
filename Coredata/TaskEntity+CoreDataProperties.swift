//
//  TaskEntity+CoreDataProperties.swift
//  SmartHutManager
//
//  Created by Darius Ogletree on 1/11/25.
//
//

import Foundation
import CoreData


extension TaskEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TaskEntity> {
        return NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
    }

    @NSManaged public var isComplete: Bool
    @NSManaged public var name: String?
    @NSManaged public var taskDescription: String?
    @NSManaged public var workOrder: WorkOrder?

}

extension TaskEntity : Identifiable {

}
