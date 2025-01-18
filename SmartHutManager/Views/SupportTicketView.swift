import SwiftUI
import CoreData

struct SupportTicketView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var ticketDescription = ""
    @State private var selectedPriority = "Low"
    @State private var tickets: [Ticket] = [] // Replace with Core Data Fetch if using Core Data
    
    let priorities = ["Low", "Medium", "High"]
    
    var body: some View {
        NavigationView {
            VStack {
                // Create Ticket Form
                Form {
                    Section(header: Text("New Ticket")) {
                        TextField("Description", text: $ticketDescription)
                        Picker("Priority", selection: $selectedPriority) {
                            ForEach(priorities, id: \.self) { priority in
                                Text(priority)
                            }
                        }
                        Button(action: createTicket) {
                            Text("Submit Ticket")
                        }
                    }
                }
                
                // List of Tickets
                List(tickets, id: \.id) { ticket in
                    VStack(alignment: .leading) {
                        Text(ticket.description).font(.headline)
                        Text("Priority: \(ticket.priority)")
                    }
                }
            }
            .navigationTitle("Support Tickets")
        }
    }
    
    private func createTicket() {
        let newTicket = Ticket(description: ticketDescription, priority: selectedPriority)
        tickets.append(newTicket)
        ticketDescription = ""
        selectedPriority = "Low"
        // Persist ticket using Core Data or Firebase
    }
}

// Example Ticket Model
struct Ticket: Identifiable {
    let id = UUID()
    let description: String
    let priority: String
}
