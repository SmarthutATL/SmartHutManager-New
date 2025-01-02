//
//  UninvoicedWorkOrderRow.swift
//  SmartHutManager
//
//  Created by Darius Ogletree on 1/2/25.
//

import SwiftUI

// MARK: - Uninvoiced Work Order Row
struct UninvoicedWorkOrderRow: View {
    let workOrder: WorkOrder
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(workOrder.customer?.name ?? "Unknown Customer")
                .font(.headline)
            Text("Category: \(workOrder.category ?? "N/A")")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Date: \(workOrder.date ?? Date(), style: .date)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
