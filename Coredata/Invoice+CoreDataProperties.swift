//
//  Invoice+CoreDataProperties.swift
//  SmartHutManager
//
//  Created by Darius Ogletree on 10/13/24.
//
//

import Foundation
import CoreData


extension Invoice {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Invoice> {
        return NSFetchRequest<Invoice>(entityName: "Invoice")
    }

    @NSManaged public var dueDate: Date?
    @NSManaged public var invoiceNotes: String?
    @NSManaged public var invoiceNumber: Int16
    @NSManaged public var issueDate: Date?
    @NSManaged public var itemizedServices: Data?
    @NSManaged public var status: String?
    @NSManaged public var subtotal: Double
    @NSManaged public var taxPercentage: Double
    @NSManaged public var totalAmount: Double
    @NSManaged public var isCallback: Bool
    @NSManaged public var customer: Customer?
    @NSManaged public var workOrder: WorkOrder?
    @NSManaged public var paymentMethod: String?
}

extension Invoice : Identifiable {

}
