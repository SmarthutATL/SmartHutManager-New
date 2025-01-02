import SwiftUI
import UniformTypeIdentifiers
import CoreData

struct InventoryReportsView: View {
    let context: NSManagedObjectContext
    @StateObject private var viewModel: InventoryViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var selectedFilter: String? = nil
    @State private var reportItems: [Inventory] = []
    @State private var isExportingCSV: Bool = false
    @State private var isExportingPDF: Bool = false
    @State private var exportURL: URL?
    @State private var showScheduleDialog: Bool = false

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
            
            actionButtons
            
            Spacer()
        }
        .navigationTitle("Reports")
        .background(Color(.systemBackground).edgesIgnoringSafeArea(.all))
        .fileExporter(
            isPresented: $isExportingCSV,
            document: CSVDocument(url: exportURL),
            contentType: .commaSeparatedText,
            defaultFilename: "InventoryReport"
        ) { result in
            handleExportResult(result)
        }
        .sheet(isPresented: $isExportingPDF) {
            PDFPreviewView(items: reportItems)
        }
        .sheet(isPresented: $showScheduleDialog) {
            ScheduleReportsView(onSchedule: scheduleReport)
        }
    }

    // MARK: - Header View
    private var headerView: some View {
        Text("Inventory Reports")
            .font(.largeTitle)
            .padding()
    }

    // MARK: - Admin Filter Chips
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

    // MARK: - Technician Header
    private var technicianHeader: some View {
        Text("Viewing inventory assigned to you")
            .font(.headline)
            .foregroundColor(.gray)
            .padding()
    }

    // MARK: - Report Preview
    private var reportPreview: some View {
        List(reportItems, id: \.self) { item in
            NavigationLink(destination: InventoryDetailView(item: item)) {
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
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Generate Report Button
            Button(action: generateReport) {
                HStack {
                    Spacer()
                    Text("Generate Report")
                        .font(.system(size: 17, weight: .semibold))
                    Spacer()
                }
                .padding()
                .background(authViewModel.isLoading ? Color(.systemGray5) : Color(.systemBlue))
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(authViewModel.isLoading)

            // Export Buttons (CSV and PDF)
            HStack(spacing: 12) {
                Button(action: exportAsCSV) {
                    HStack {
                        Spacer()
                        Text("Export CSV")
                            .font(.system(size: 15, weight: .medium))
                        Spacer()
                    }
                    .padding()
                    .background(reportItems.isEmpty ? Color(.systemGray5) : Color(.systemGray6))
                    .foregroundColor(reportItems.isEmpty ? Color(.systemGray) : Color(.label))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                }
                .disabled(reportItems.isEmpty)

                Button(action: exportAsPDF) {
                    HStack {
                        Spacer()
                        Text("Export PDF")
                            .font(.system(size: 15, weight: .medium))
                        Spacer()
                    }
                    .padding()
                    .background(reportItems.isEmpty ? Color(.systemGray5) : Color(.systemGray6))
                    .foregroundColor(reportItems.isEmpty ? Color(.systemGray) : Color(.label))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                }
                .disabled(reportItems.isEmpty)
            }

            // Schedule Reports Button
            Button(action: { showScheduleDialog = true }) {
                HStack {
                    Spacer()
                    Text("Schedule Reports")
                        .font(.system(size: 17, weight: .semibold))
                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                .foregroundColor(Color(.label))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Generate Report
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

    // MARK: - Export as CSV
    private func exportAsCSV() {
        let csvData = createCSVData(from: reportItems)
        exportURL = saveCSVToFile(data: csvData)
        isExportingCSV = true
    }

    // MARK: - Export as PDF
    private func exportAsPDF() {
        isExportingPDF = true
    }

    // MARK: - Schedule Report
    private func scheduleReport(frequency: ReportFrequency) {
        print("Report scheduled: \(frequency.rawValue)")
    }

    // MARK: - Handle Export Result
    private func handleExportResult(_ result: Result<URL, Error>) {
        if case .success(let url) = result {
            print("File saved to \(url)")
        } else {
            print("File export failed.")
        }
    }

    // MARK: - Create CSV Data
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

    // MARK: - Save CSV to File
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
}
