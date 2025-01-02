import SwiftUI
import CoreData

struct TechnicianPerformanceView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Tradesmen.name, ascending: true)]
    ) var technicians: FetchedResults<Tradesmen>

    @State private var selectedTechnician: Tradesmen? = nil
    @State private var workOrdersCache: [Tradesmen: [WorkOrder]] = [:]
    @State private var loadingTechnician: Tradesmen? = nil

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Dynamic background color
            Color(colorScheme == .dark ? .black : .white)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                // Header
                headerView

                if technicians.isEmpty {
                    noTechniciansView
                } else {
                    // Technician Picker
                    technicianPicker

                    // Performance Metrics
                    Spacer()
                    Group {
                        if let technician = selectedTechnician {
                            if loadingTechnician == technician {
                                loadingMetricsView
                            } else if let metrics = calculateMetrics(for: technician) {
                                performanceMetricsView(for: technician, metrics: metrics)
                            } else {
                                placeholderMetricsView
                            }
                        } else {
                            placeholderMetricsView
                        }
                    }
                    Spacer()
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
        }
        .onAppear {
            preCacheWorkOrders()
            if let firstTechnician = technicians.first {
                selectTechnician(firstTechnician)
            }
        }
    }

    // MARK: - Header View
    private var headerView: some View {
        Text("Technician Performance")
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(colorScheme == .dark ? .white : .black)
            .shadow(radius: 5)
    }

    // MARK: - No Technicians View
    private var noTechniciansView: some View {
        VStack {
            Spacer()
            Text("No technicians available.")
                .font(.title3)
                .foregroundColor(.gray)
                .padding()
            Spacer()
        }
    }

    private var technicianPicker: some View {
        Picker("Select Technician", selection: $selectedTechnician) {
            ForEach(technicians) { technician in
                Text(technician.name ?? "Unknown").tag(technician as Tradesmen?)
            }
        }
        .pickerStyle(WheelPickerStyle())
        .frame(maxWidth: .infinity)
        .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
        .cornerRadius(12)
        .padding(.horizontal)
        .onChange(of: selectedTechnician) { technician in
            if let technician = technician {
                selectTechnician(technician)
            }
        }
    }

    // MARK: - Placeholder and Loading Views
    private var placeholderMetricsView: some View {
        VStack {
            Text("Select a technician to view their performance.")
                .font(.body)
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.8))
                .padding()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.05))
        .cornerRadius(15)
    }

    private var loadingMetricsView: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: colorScheme == .dark ? .white : .black))
                .scaleEffect(1.5)
            Text("Loading metrics...")
                .font(.body)
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.8))
        }
        .padding()
        .background(colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.05))
        .cornerRadius(15)
    }

    // MARK: - Performance Metrics View
    private func performanceMetricsView(for technician: Tradesmen, metrics: Metrics) -> some View {
        VStack(spacing: 16) {
            Text("Performance Metrics for \(technician.name ?? "Unknown")")
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? .white : .black)

            performanceMetricCard(title: "Completion Percentage", value: "\(String(format: "%.1f", metrics.completionPercentage))%")
            performanceMetricCard(title: "Total Work Orders", value: "\(metrics.totalOrders)")
            performanceMetricCard(title: "Completed Orders", value: "\(metrics.completedOrders)")
            performanceMetricCard(title: "Incomplete Orders", value: "\(metrics.incompleteOrders)")
        }
        .padding()
        .background(colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.05))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.2), radius: 5)
        .padding(.horizontal)
    }

    private func performanceMetricCard(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.8))
            Spacer()
            Text(value)
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? .white : .black)
        }
        .padding(.vertical, 5)
        .padding(.horizontal)
        .background(colorScheme == .dark ? Color.blue.opacity(0.6) : Color.blue.opacity(0.2))
        .cornerRadius(12)
    }

    // MARK: - Technician Selection
    private func selectTechnician(_ technician: Tradesmen) {
        guard selectedTechnician != technician else { return }
        selectedTechnician = technician
        if workOrdersCache[technician] == nil {
            loadWorkOrders(for: technician)
        }
    }

    // MARK: - Pre-Cache Work Orders
    private func preCacheWorkOrders() {
        for technician in technicians {
            if workOrdersCache[technician] == nil {
                loadWorkOrders(for: technician)
            }
        }
    }

    // MARK: - Fetch Work Orders
    private func loadWorkOrders(for technician: Tradesmen) {
        loadingTechnician = technician
        DispatchQueue.global(qos: .userInitiated).async {
            let fetchRequest: NSFetchRequest<WorkOrder> = WorkOrder.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "ANY tradesmen == %@", technician)
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \WorkOrder.date, ascending: true)]

            do {
                let fetchedOrders = try viewContext.fetch(fetchRequest)
                DispatchQueue.main.async {
                    workOrdersCache[technician] = fetchedOrders
                    loadingTechnician = nil
                }
            } catch {
                print("Failed to fetch work orders: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    loadingTechnician = nil
                }
            }
        }
    }

    // MARK: - Metrics Calculation
    private func calculateMetrics(for technician: Tradesmen) -> Metrics? {
        guard let workOrders = workOrdersCache[technician] else {
            return nil
        }

        let completedOrders = workOrders.filter { $0.status?.lowercased() == "completed" }.count
        let incompleteOrders = workOrders.filter { $0.status?.lowercased() == "incomplete" }.count
        let totalOrders = workOrders.count

        let completionPercentage = totalOrders > 0 ? (Double(completedOrders) / Double(totalOrders)) * 100 : 0.0

        return Metrics(
            completionPercentage: completionPercentage,
            totalOrders: totalOrders,
            completedOrders: completedOrders,
            incompleteOrders: incompleteOrders
        )
    }

    struct Metrics {
        let completionPercentage: Double
        let totalOrders: Int
        let completedOrders: Int
        let incompleteOrders: Int
    }
}
