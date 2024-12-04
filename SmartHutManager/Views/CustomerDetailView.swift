import SwiftUI
import CoreData
import MapKit

struct CustomerDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var customer: Customer
    
    @State private var isEditing = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Customer Header with Name
                customerHeader
                
                // Action Buttons (Message, Call, Mail, Request Pay)
                actionButtonsSection
                
                // Separated Customer Info Sections
                customerPhoneSection
                customerEmailSection
                customerAddressSectionWithMap
                
                // Work Orders Section
                workOrdersSection
            }
            .padding(.horizontal) // Add consistent padding for all sections
        }
        .navigationBarItems(trailing: Button("Edit") {
            isEditing.toggle()
        }
        .sheet(isPresented: $isEditing) {
            CustomerEditView(customer: customer) // Present the new edit view
        })
        .background(Color.black.edgesIgnoringSafeArea(.all)) // Dark background
    }
    
    // MARK: - Customer Header
    private var customerHeader: some View {
        VStack {
            Text(customer.name ?? "Unknown Name")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        HStack(spacing: 20) {
            // Message Button
            actionButton(icon: "message.fill", label: "Message", color: .blue) {
                if let phoneNumber = customer.phoneNumber, let url = URL(string: "sms:\(phoneNumber)") {
                    UIApplication.shared.open(url)
                }
            }
            
            // Call Button
            actionButton(icon: "phone.fill", label: "Call", color: .green) {
                if let phoneNumber = customer.phoneNumber, let url = URL(string: "tel:\(phoneNumber)") {
                    UIApplication.shared.open(url)
                }
            }
            
            // Mail Button
            actionButton(icon: "envelope.fill", label: "Mail", color: .red) {
                if let email = customer.email, let url = URL(string: "mailto:\(email)") {
                    UIApplication.shared.open(url)
                }
            }
            
            // Request Pay Button
            actionButton(icon: "dollarsign.circle.fill", label: "Pay", color: .orange) {
                print("Request Pay tapped")
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 4)
        .frame(maxWidth: .infinity) // Stretches to the edges
    }

    // MARK: - Action Button Helper
    private func actionButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .foregroundColor(color)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)

                Text(label)
                    .font(.footnote)
                    .foregroundColor(.primary)
                    .padding(.top, 5)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Separated Customer Info Sections
    private var customerPhoneSection: some View {
        infoSection(icon: "phone.fill", label: "Mobile", content: customer.phoneNumber ?? "No Phone", color: .blue)
    }

    private var customerEmailSection: some View {
        infoSection(icon: "envelope.fill", label: "Email", content: customer.email ?? "No Email", color: .green)
    }

    // MARK: - Customer Address Section with Map
    private var customerAddressSectionWithMap: some View {
        VStack(spacing: 16) {
            // Address text with icon
            infoSection(icon: "map.fill", label: "Address", content: customer.address ?? "No Address", color: .orange)
                .onTapGesture {
                    if let address = customer.address {
                        openInMaps(address: address)
                    }
                }
            
            // Add MapView if address is available
            if let address = customer.address, !address.isEmpty {
                MapView(address: address)
                    .frame(height: 200)
                    .cornerRadius(12)
                    .shadow(radius: 8, x: 0, y: 4)
                    .frame(maxWidth: .infinity) // Stretches the map view to the edges
                    .onTapGesture {
                        openInMaps(address: address) // Make map tappable
                    }
            }
        }
    }

    // MARK: - Info Section Helper
    private func infoSection(icon: String, label: String, content: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30, height: 30)
                .background(Circle().fill(Color.white).shadow(radius: 5))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text(content)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            .padding(.leading, 8)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)  // Ensures all sections are the same width
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
    }
    
    // MARK: - Work Orders Section
    private var workOrdersSection: some View {
        VStack(alignment: .leading) {
            Text("Work Orders")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.vertical)
            
            if let workOrders = customer.workOrders?.allObjects as? [WorkOrder], !workOrders.isEmpty {
                ForEach(workOrders, id: \.objectID) { workOrder in
                    // Use NavigationLink to navigate to the work order's detail view
                    NavigationLink(destination: WorkOrderDetailView(workOrder: workOrder)) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("#\(workOrder.workOrderNumber)")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Job: \(workOrder.category ?? "Unknown Category")")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Date: \(formattedDate(workOrder.date))")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text("Status: \(workOrder.status ?? "Unknown")")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(UIColor.systemGray5))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .frame(maxWidth: .infinity)
                    }
                }
            } else {
                Text("No work orders available")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }

    // MARK: - Date Formatting Function
    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "No Date" }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        return dateFormatter.string(from: date)
    }
    
    // MARK: - Open in Maps Function
    private func openInMaps(address: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, error in
            if let placemark = placemarks?.first, let location = placemark.location {
                let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
                mapItem.name = address
                mapItem.openInMaps(launchOptions: nil)
            } else {
                print("Failed to open map for address: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
}

// MARK: - Navigate to WorkOrderDetailView
private func navigateToWorkOrderDetail(_ workOrder: WorkOrder, navigationController: UINavigationController?) {
    // Create the WorkOrderDetailView wrapped in a UIHostingController
    let workOrderDetailView = WorkOrderDetailView(workOrder: workOrder)
    let hostingController = UIHostingController(rootView: workOrderDetailView)
    
    // Use the provided navigationController to push the WorkOrderDetailView
    navigationController?.pushViewController(hostingController, animated: true)
}

// MARK: - Section View for Reusability
struct SectionView: View {
    let icon: String
    let label: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.gray)
                    .frame(width: 24, height: 24)
                Text(label.capitalized)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            Text(content)
                .font(.title3)
                .foregroundColor(.white)  // White text for dark background
                .padding(.top, 1)
            
            Divider()
                .background(Color.gray)
        }
        .padding(.vertical, 5)
        .padding(.horizontal)
        .background(Color(UIColor.systemGray5))
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(.bottom)
    }
}
