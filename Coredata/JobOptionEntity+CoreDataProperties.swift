//
//  JobOptionEntity+CoreDataProperties.swift
//  SmartHutManager
//
//  Created by Darius Ogletree on 12/14/24.
//
//

import Foundation
import CoreData


extension JobOptionEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<JobOptionEntity> {
        return NSFetchRequest<JobOptionEntity>(entityName: "JobOptionEntity")
    }

    @NSManaged public var name: String?
    @NSManaged public var price: Double
    @NSManaged public var jobDescription: String?
    @NSManaged public var category: JobCategoryEntity?

}

extension JobOptionEntity : Identifiable {

}
