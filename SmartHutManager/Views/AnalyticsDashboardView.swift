import SwiftUI
import CoreData
import Charts

struct AnalyticsDashboardView: View {
    let context: NSManagedObjectContext
    @FetchRequest(
        entity: Inventory.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Inventory.name, ascending: true)]
    ) private var inventoryItems: FetchedResults<Inventory>
    
    private var totalInventoryValue: Double {
        inventoryItems.reduce(0) { $0 + ($1.price * Double($1.quantity)) }
    }
    
    private var lowStockItems: [Inventory] {
        var uniqueNames = Set<String>()
        return inventoryItems.filter { item in
            item.quantity < 10 && item.tradesmen == nil && uniqueNames.insert(item.name ?? "").inserted
        }
    }
    
    private var stockUsageTrend: [(String, Int)] {
        let calendar = Calendar.current
        var usageData: [String: Int] = [:]
        
        for item in inventoryItems {
            for usage in item.usageHistory {
                if let date = usage.date {
                    let month = calendar.component(.month, from: date)
                    let year = calendar.component(.year, from: date)
                    let monthYearKey = "\(calendar.monthSymbols[month - 1]) \(year)"
                    
                    usageData[monthYearKey, default: 0] += Int(usage.quantityUsed)
                }
            }
        }
        
        let sortedData = usageData.sorted { $0.key < $1.key }
        return sortedData
    }
    
    private var topLowStockItems: [Inventory] {
        lowStockItems.sorted { $0.quantity < $1.quantity }.prefix(5).map { $0 }
    }
    
    private var inventoryTurnoverRate: Double {
        let totalUsage = inventoryItems.reduce(0) { $0 + $1.usageHistory.reduce(0) { $0 + Double($1.quantityUsed) } }
        return totalInventoryValue == 0 ? 0 : totalUsage / totalInventoryValue
    }
    
    private var mostUsedItems: [Inventory] {
        let calendar = Calendar.current
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        
        // Filter items used in the last month
        let itemsUsedLastMonth = inventoryItems.filter { item in
            item.usageHistory.contains { usage in
                if let usageDate = usage.date {
                    return usageDate >= lastMonth
                }
                return false
            }
        }
        
        // Sort by total quantity used
        let sortedItems = itemsUsedLastMonth.sorted { item1, item2 in
            let totalUsage1 = item1.usageHistory.reduce(0) { $0 + $1.quantityUsed }
            let totalUsage2 = item2.usageHistory.reduce(0) { $0 + $1.quantityUsed }
            return totalUsage1 > totalUsage2
        }
        
        // Return the top 5 items
        return Array(sortedItems.prefix(5))
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Total Inventory Value
                analyticsCard(title: "Total Inventory Value", value: String(format: "$%.2f", totalInventoryValue)) {
                    EmptyView()
                }
                
                // Items with Low Stock
                analyticsCard(title: "Items with Low Stock", value: "\(lowStockItems.count)") {
                    ForEach(lowStockItems, id: \.self) { item in
                        Text("\(item.name ?? "Unknown") - Qty: \(item.quantity)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                // Top 5 Low Stock Items
                analyticsCard(title: "Top 5 Low Stock Items", value: "") {
                    if topLowStockItems.isEmpty {
                        VStack(spacing: 8) {
                            Text("No low stock items.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text("All inventory items are sufficiently stocked.")
                                .font(.footnote)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        ForEach(topLowStockItems, id: \.self) { item in
                            Text("\(item.name ?? "Unknown") - Qty: \(item.quantity)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // Inventory Turnover Rate
                analyticsCard(title: "Inventory Turnover Rate", value: String(format: "%.2f", inventoryTurnoverRate)) {
                    Text("Turnover rate indicates how efficiently inventory is used.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                // Most Frequently Used Items
                analyticsCard(title: "Top 5 Most Used Items", value: "") {
                    if mostUsedItems.isEmpty {
                        VStack(spacing: 8) {
                            Text("No frequently used items.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text("Usage data is currently unavailable or insufficient.")
                                .font(.footnote)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        ForEach(mostUsedItems, id: \.self) { item in
                            Text("\(item.name ?? "Unknown") - Used: \(item.usageHistory.reduce(0) { $0 + $1.quantityUsed })")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // Trends Over Time (Chart)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Stock Usage Trends")
                        .font(.headline)
                    
                    if stockUsageTrend.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "chart.bar.xaxis")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.gray)
                            Text("No usage data available")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text("Once inventory is updated with usage data, you'll see trends here.")
                                .font(.footnote)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                        }
                        .frame(height: 200)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        )
                    } else {
                        Chart(stockUsageTrend, id: \.0) { data in
                            LineMark(
                                x: .value("Month", data.0),
                                y: .value("Stock Used", data.1)
                            )
                            .foregroundStyle(.blue)
                        }
                        .frame(height: 200)
                    }
                }
            }
            .padding()
            .navigationTitle("Analytics Dashboard")
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        }
    }
    
    @ViewBuilder
    private func analyticsCard<Content: View>(
        title: String,
        value: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            Text(value)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.blue)

            content()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}
