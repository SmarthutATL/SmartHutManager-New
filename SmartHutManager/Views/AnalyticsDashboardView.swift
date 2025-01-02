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
        // Filter for items with low stock, eliminate duplicates, and include only warehouse items
        var uniqueNames = Set<String>()
        return inventoryItems.filter { item in
            item.quantity < 10 && item.tradesmen == nil && uniqueNames.insert(item.name ?? "").inserted
        }
    }
    
    private var stockUsageTrend: [(String, Int)] {
        let calendar = Calendar.current
        var usageData: [String: Int] = [:]
        
        // Group inventory usage data by month
        for item in inventoryItems {
            for usage in item.usageHistory { // Directly iterate over usageHistory
                if let date = usage.date {
                    let month = calendar.component(.month, from: date)
                    let year = calendar.component(.year, from: date)
                    let monthYearKey = "\(calendar.monthSymbols[month - 1]) \(year)"
                    
                    usageData[monthYearKey, default: 0] += Int(usage.quantityUsed)
                }
            }
        }
        
        // Sort data by month and year
        let sortedData = usageData.sorted { $0.key < $1.key }
        print("Stock Usage Trend Data: \(sortedData)") // Debug print
        return sortedData
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Total Inventory Value
                analyticsCard(title: "Total Inventory Value", value: String(format: "$%.2f", totalInventoryValue)) {
                    EmptyView() // Optional placeholder for no additional content
                }
                
                // Items with Low Stock
                analyticsCard(title: "Items with Low Stock", value: "\(lowStockItems.count)") {
                    ForEach(lowStockItems, id: \.self) { item in
                        Text("\(item.name ?? "Unknown") - Qty: \(item.quantity)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                // Trends Over Time (Chart)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Stock Usage Trends")
                        .font(.headline)
                    
                    if stockUsageTrend.isEmpty {
                        // Display an enhanced empty state view
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
                        // Display the chart when data is available
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

            content() // Call the trailing closure here
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}
