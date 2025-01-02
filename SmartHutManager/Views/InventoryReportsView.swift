import SwiftUI
import UniformTypeIdentifiers
import CoreData

struct InventoryReportsView: View {
    let context: NSManagedObjectContext
    @StateObject private var viewModel: InventoryViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var selectedFilter: String? = nil
    @State private var reportItems: [Inventory] = []
    @State private var isExporting: Bool = false
    @State private var exportURL: URL?

    init(context: NSManagedObjectContext) {
        self.context = context
        _viewModel = StateObject(wrappedValue: InventoryViewModel(context: context))
    }

    var body: some View {
        VStack {
            headerView
            if authViewModel.userRole == "admin" {
                adminFilterChips
            } else if authViewModel.userRole == "technician" {
                technicianHeader
            }
            reportPreview

            Button(action: generateReport) {
                Text("Generate Report")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding()
            }
            .disabled(authViewModel.isLoading)

            if authViewModel.userRole == "admin" {
                Button(action: exportReport) {
                    Text("Export as CSV")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding([.horizontal, .bottom])
                }
                .disabled(reportItems.isEmpty)
            }

            Spacer()
        }
        .navigationTitle("Reports")
        .background(Color(.systemBackground).edgesIgnoringSafeArea(.all))
        .fileExporter(
            isPresented: $isExporting,
            document: CSVDocument(url: exportURL),
            contentType: .commaSeparatedText,
            defaultFilename: "InventoryReport"
        ) { result in
            if case .success(let url) = result {
                print("File saved to \(url)")
            } else {
                print("File export failed.")
            }
        }
    }

    private var headerView: some View {
        Text("Inventory Reports")
            .font(.largeTitle)
            .padding()
    }

    private var adminFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                FilterChip(title: "Low Stock", isSelected: selectedFilter == "Low Stock") {
                    selectedFilter = selectedFilter == "Low Stock" ? nil : "Low Stock"
                }
                FilterChip(title: "High Stock", isSelected: selectedFilter == "High Stock") {
                    selectedFilter = selectedFilter == "High Stock" ? nil : "High Stock"
                }
                FilterChip(title: "Assigned Inventory", isSelected: selectedFilter == "Assigned Inventory") {
                    selectedFilter = selectedFilter == "Assigned Inventory" ? nil : "Assigned Inventory"
                }
                FilterChip(title: "All Items", isSelected: selectedFilter == nil) {
                    selectedFilter = nil
                }
            }
            .padding(.horizontal)
        }
    }

    private var technicianHeader: some View {
        Text("Viewing inventory assigned to you")
            .font(.headline)
            .foregroundColor(.gray)
            .padding()
    }

    private var reportPreview: some View {
        List(reportItems, id: \.self) { item in
            VStack(alignment: .leading, spacing: 5) {
                Text(item.name ?? "Unknown").font(.headline)
                Text("Price: $\(item.price, specifier: "%.2f") | Qty: \(item.quantity)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                if let tradesman = item.tradesmen {
                    Text("Assigned to: \(tradesman.name ?? "Unknown Technician")")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
    }

    private func generateReport() {
        if authViewModel.userRole == "admin" {
            switch selectedFilter {
            case "Low Stock":
                reportItems = viewModel.inventoryItems.filter { $0.quantity < 10 }
            case "High Stock":
                reportItems = viewModel.inventoryItems.filter { $0.quantity >= 10 }
            case "Assigned Inventory":
                reportItems = viewModel.inventoryItems.filter { $0.tradesmen != nil }
            default:
                reportItems = viewModel.inventoryItems
            }
        } else if authViewModel.userRole == "technician" {
            guard let email = authViewModel.currentUserEmail else { return }
            let tradesman = viewModel.tradesmen.first { $0.email == email }
            reportItems = tradesman.map { viewModel.getInventoryForTradesman($0) } ?? []
        }
    }

    private func exportReport() {
        let csvData = createCSVData(from: reportItems)
        exportURL = saveCSVToFile(data: csvData)
        isExporting = true
    }

    private func createCSVData(from items: [Inventory]) -> String {
        var csv = "Name,Price,Quantity,Assigned To\n"
        for item in items {
            let name = item.name ?? "Unknown"
            let price = String(format: "%.2f", item.price)
            let quantity = "\(item.quantity)"
            let assignedTo = item.tradesmen?.name ?? "Unassigned"
            csv += "\(name),\(price),\(quantity),\(assignedTo)\n"
        }
        return csv
    }

    private func saveCSVToFile(data: String) -> URL? {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("InventoryReport.csv")
        do {
            try data.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print("Failed to save CSV file: \(error.localizedDescription)")
            return nil
        }
    }
}

struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    let url: URL?

    init(url: URL?) {
        self.url = url
    }

    init(configuration: ReadConfiguration) throws {
        self.url = nil
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let url = url else { throw CocoaError(.fileWriteUnknown) }
        return try FileWrapper(url: url)
    }
}
