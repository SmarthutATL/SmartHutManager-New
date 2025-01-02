//
//  InventoryDetailView.swift
//  SmartHutManager
//
//  Created by Darius Ogletree on 1/2/25.
//

import SwiftUI

struct InventoryDetailView: View {
    let item: Inventory

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(item.name ?? "Unknown Item")
                .font(.largeTitle)
                .padding(.bottom)

            Text("Price: $\(item.price, specifier: "%.2f")")
            Text("Quantity: \(item.quantity)")
            
            if let tradesman = item.tradesmen {
                Text("Assigned to: \(tradesman.name ?? "Unknown")")
            } else {
                Text("Not Assigned")
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Inventory Details")
    }
}
