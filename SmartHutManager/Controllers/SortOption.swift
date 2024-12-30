import Foundation

enum SortOption: Hashable, CaseIterable {
    case date(ascending: Bool)
    case name(ascending: Bool)
    case price(ascending: Bool)
    case workOrderNumber
    case status
    case category

    // Computed property for determining ascending order for date
    var isDateAscending: Bool {
        if case .date(let ascending) = self {
            return ascending
        }
        return true
    }

    // Comparator function for dynamic sorting
    var comparator: (Any, Any) -> Bool {
        switch self {
        case .date(let ascending):
            return { (lhs, rhs) in
                guard let lhs = lhs as? WorkOrder, let rhs = rhs as? WorkOrder else { return false }
                return ascending ? (lhs.date ?? Date()) < (rhs.date ?? Date()) : (lhs.date ?? Date()) > (rhs.date ?? Date())
            }
        case .name(let ascending):
            return { (lhs, rhs) in
                if let lhs = lhs as? Material, let rhs = rhs as? Material {
                    return ascending ? lhs.name < rhs.name : lhs.name > rhs.name
                } else if let lhs = lhs as? WorkOrder, let rhs = rhs as? WorkOrder {
                    return ascending ? (lhs.category ?? "") < (rhs.category ?? "") : (lhs.category ?? "") > (rhs.category ?? "")
                }
                return false
            }
        case .price(let ascending):
            return { (lhs, rhs) in
                guard let lhs = lhs as? Material, let rhs = rhs as? Material else { return false }
                return ascending ? lhs.price < rhs.price : lhs.price > rhs.price
            }
        case .workOrderNumber:
            return { (lhs, rhs) in
                guard let lhs = lhs as? WorkOrder, let rhs = rhs as? WorkOrder else { return false }
                return lhs.workOrderNumber < rhs.workOrderNumber
            }
        case .status:
            return { (lhs, rhs) in
                guard let lhs = lhs as? WorkOrder, let rhs = rhs as? WorkOrder else { return false }
                let statusOrder = ["Open", "Completed", "Incomplete"]
                return (statusOrder.firstIndex(of: lhs.status ?? "") ?? 3) < (statusOrder.firstIndex(of: rhs.status ?? "") ?? 3)
            }
        case .category:
            return { (lhs, rhs) in
                guard let lhs = lhs as? WorkOrder, let rhs = rhs as? WorkOrder else { return false }
                return (lhs.category ?? "").localizedCaseInsensitiveCompare(rhs.category ?? "") == .orderedAscending
            }
        }
    }

    // Display name for the sort option
    var displayName: String {
        switch self {
        case .date(let ascending): return ascending ? "Date ↑" : "Date ↓"
        case .name(let ascending): return ascending ? "Name ↑" : "Name ↓"
        case .price(let ascending): return ascending ? "Price ↑" : "Price ↓"
        case .workOrderNumber: return "Work Order Number"
        case .status: return "Status"
        case .category: return "Category"
        }
    }

    // List of all sort options
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
