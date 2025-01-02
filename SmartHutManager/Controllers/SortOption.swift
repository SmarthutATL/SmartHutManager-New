import Foundation

enum SortOption: Hashable, CaseIterable {
    case date(ascending: Bool)
    case name(ascending: Bool)
    case price(ascending: Bool)
    case workOrderNumber
    case status
    case category

    /// Function to compare two items based on the selected sort option
    func comparator<T>(_ lhs: T, _ rhs: T) -> Bool {
        if let lhs = lhs as? Inventory, let rhs = rhs as? Inventory {
            return compareInventory(lhs: lhs, rhs: rhs)
        } else if let lhs = lhs as? WorkOrder, let rhs = rhs as? WorkOrder {
            return compareWorkOrder(lhs: lhs, rhs: rhs)
        }
        return false
    }

    /// Compares Inventory objects
    private func compareInventory(lhs: Inventory, rhs: Inventory) -> Bool {
        switch self {
        case .date(let ascending):
            // If Inventory doesn't have a `date`, remove this case
            return ascending ? (lhs.date ?? Date.distantPast) < (rhs.date ?? Date.distantPast)
                             : (lhs.date ?? Date.distantPast) > (rhs.date ?? Date.distantPast)

        case .name(let ascending):
            let lhsName = lhs.name ?? ""
            let rhsName = rhs.name ?? ""
            return ascending ? lhsName < rhsName : lhsName > rhsName

        case .price(let ascending):
            return ascending ? lhs.price < rhs.price : lhs.price > rhs.price

        default:
            return false
        }
    }

    /// Compares WorkOrder objects
    private func compareWorkOrder(lhs: WorkOrder, rhs: WorkOrder) -> Bool {
        switch self {
        case .date(let ascending):
            let lhsDate = lhs.date ?? Date.distantPast
            let rhsDate = rhs.date ?? Date.distantPast
            return ascending ? lhsDate < rhsDate : lhsDate > rhsDate

        case .name(let ascending):
            let lhsCategory = lhs.category ?? ""
            let rhsCategory = rhs.category ?? ""
            return ascending ? lhsCategory < rhsCategory : rhsCategory > lhsCategory

        case .workOrderNumber:
            let lhsNumber = String(lhs.workOrderNumber)
            let rhsNumber = String(rhs.workOrderNumber)
            return lhsNumber < rhsNumber

        case .status:
            let statusOrder = ["Open", "In Progress", "Completed"]
            let lhsIndex = statusOrder.firstIndex(of: lhs.status ?? "") ?? statusOrder.count
            let rhsIndex = statusOrder.firstIndex(of: rhs.status ?? "") ?? statusOrder.count
            return lhsIndex < rhsIndex

        case .category:
            let lhsCategory = lhs.category ?? ""
            let rhsCategory = rhs.category ?? ""
            return lhsCategory.localizedCaseInsensitiveCompare(rhsCategory) == .orderedAscending

        default:
            return false
        }
    }

    /// Computed property to check if the sort option is date ascending
    var isDateAscending: Bool {
        if case .date(let ascending) = self {
            return ascending
        }
        return false
    }

    /// All cases for the `SortOption` enum
    static var allCases: [SortOption] {
        [
            .date(ascending: true), .date(ascending: false),
            .name(ascending: true), .name(ascending: false),
            .price(ascending: true), .price(ascending: false),
            .workOrderNumber,
            .status,
            .category
        ]
    }
}
