//
//  JobCategoryEntity+CoreDataProperties.swift
//  SmartHutManager
//
//  Created by Darius Ogletree on 12/14/24.
//
//

import Foundation
import CoreData


extension JobCategoryEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<JobCategoryEntity> {
        return NSFetchRequest<JobCategoryEntity>(entityName: "JobCategoryEntity")
    }

    @NSManaged public var name: String?
    @NSManaged public var jobs: NSSet?

}

// MARK: Generated accessors for jobs
extension JobCategoryEntity {

    @objc(addJobsObject:)
    @NSManaged public func addToJobs(_ value: JobOptionEntity)

    @objc(removeJobsObject:)
    @NSManaged public func removeFromJobs(_ value: JobOptionEntity)

    @objc(addJobs:)
    @NSManaged public func addToJobs(_ values: NSSet)

    @objc(removeJobs:)
    @NSManaged public func removeFromJobs(_ values: NSSet)

}

extension JobCategoryEntity : Identifiable {

}
