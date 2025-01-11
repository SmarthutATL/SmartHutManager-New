//
//  AppAlert+CoreDataProperties.swift
//  SmartHutManager
//
//  Created by Darius Ogletree on 1/11/25.
//
//

import Foundation
import CoreData


extension AppAlert {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AppAlert> {
        return NSFetchRequest<AppAlert>(entityName: "AppAlert")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var message: String?
    @NSManaged public var isNew: Bool
    @NSManaged public var timestamp: Date?

}

extension AppAlert : Identifiable {

}
