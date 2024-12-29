import Foundation

enum DeletedItemType: String, Codable {
    case invoice
    case workOrder
    case customer
    case message
}

struct DeletedItem: Identifiable, Codable {
    var id: UUID
    var type: DeletedItemType
    var description: String
    var originalDate: Date? // For work orders or invoices
    var originalStatus: String? // For work orders or invoices
    var originalCustomerName: String? // For work orders or customers
    var originalCategory: String? // For work orders
    var originalTradesmen: [String]? // For work orders (assigned technicians)
    var originalPhoneNumber: String? // For customers
    var originalEmail: String? // For customers

    var icon: String {
        switch type {
        case .invoice:
            return "doc.text.fill"
        case .workOrder:
            return "wrench.and.screwdriver.fill"
        case .customer:
            return "person.fill"
        case .message:
            return "message.fill"
        }
    }
}
