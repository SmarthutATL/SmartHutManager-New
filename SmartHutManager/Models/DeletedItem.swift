import Foundation

enum DeletedItemType {
    case invoice
    case workOrder
}

struct DeletedItem: Identifiable {
    var id = UUID()
    var type: DeletedItemType
    var description: String

    var icon: String {
        switch type {
        case .invoice: return "doc.text.fill"
        case .workOrder: return "wrench.and.screwdriver.fill"
        }
    }
}
