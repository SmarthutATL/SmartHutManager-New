import Foundation
import CoreData

// MARK: - Sorting Options for Invoices
enum InvoiceSortOption {
    case amount(ascending: Bool)
    case date(ascending: Bool)
    
    var isDateAscending: Bool {
        if case .date(let ascending) = self {
            return ascending
        }
        return true
    }
    
    var comparator: (Invoice, Invoice) -> Bool {
        switch self {
        case .amount(let ascending):
            return { ascending ? $0.computedTotalAmount < $1.computedTotalAmount : $0.computedTotalAmount > $1.computedTotalAmount }
        case .date(let ascending):
            return { ascending ? ($0.issueDate ?? Date()) < ($1.issueDate ?? Date()) : ($0.issueDate ?? Date()) > ($1.issueDate ?? Date()) }
        }
    }
}

// MARK: - Extension to Calculate Total Amount in Invoice
extension Invoice {
    var computedTotalAmount: Double {
        let serviceTotal = itemizedServicesArray.reduce(0) { total, service in
            total + (service.unitPrice * Double(service.quantity))
        }
        let materialTotal = workOrder?.materialsArray.reduce(0) { total, material in
            total + (material.price * Double(material.quantity))
        } ?? 0.0
        let combinedSubtotal = serviceTotal + materialTotal
        let taxAmount = (combinedSubtotal * (self.taxPercentage / 100)) // Calculate the tax
        return combinedSubtotal + taxAmount // Include the tax in the total
    }
}
