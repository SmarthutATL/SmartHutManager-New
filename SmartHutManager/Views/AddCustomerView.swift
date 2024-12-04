import SwiftUI
import MapKit

struct AddCustomerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    var onCustomerCreated: (Customer) -> Void // Callback for the created customer
    
    @State private var customerName = ""
    @State private var customerEmail = ""
    @State private var customerPhone = ""
    
    // Address fields
    @State private var street = ""
    @State private var city = ""
    @State private var zipCode = ""
    
    // For Address Autocomplete
    @State private var searchCompleter = MKLocalSearchCompleter()
    @State private var searchResults = [MKLocalSearchCompletion]()
    
    // Hold the search completer delegate strongly
    @State private var searchCompleterDelegate: SearchCompleterDelegate?

    var body: some View {
        NavigationView {
            Form {
                // Section for Customer Details
                Section(header: Text("Customer Details")) {
                    TextField("Customer Name", text: $customerName)
                    TextField("Email", text: $customerEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Phone Number", text: $customerPhone)
                        .keyboardType(.phonePad)
                }
                
                // Section for Address Details with Autocomplete
                Section(header: Text("Customer Address")) {
                    // Street address with auto-complete
                    TextField("Street", text: $street)
                        .onChange(of: street) { oldValue, newValue in
                            searchCompleter.queryFragment = newValue
                        }
                    
                    // Displaying search results as the user types
                    if !searchResults.isEmpty {
                        List(searchResults, id: \.self) { completion in
                            Button(action: {
                                completeAddress(with: completion)
                            }) {
                                VStack(alignment: .leading) {
                                    Text(completion.title)
                                        .font(.body)
                                    Text(completion.subtitle)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }

                    // City and Zip code
                    TextField("City", text: $city)
                    TextField("Zip Code", text: $zipCode)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Add Customer")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        addCustomer() // Save and call the callback function
                    }
                    .disabled(customerName.isEmpty || customerEmail.isEmpty || street.isEmpty) // Disable until fields are filled
                }
            }
            .onAppear {
                let delegate = SearchCompleterDelegate(completionHandler: { results in
                    searchResults = results
                })
                searchCompleterDelegate = delegate // Hold a strong reference to the delegate
                searchCompleter.delegate = delegate // Assign the delegate to the searchCompleter
            }
        }
    }

    // Function to add a new customer
    private func addCustomer() {
        let newCustomer = Customer(context: viewContext)
        newCustomer.name = customerName
        newCustomer.email = customerEmail
        newCustomer.phoneNumber = customerPhone
        newCustomer.address = "\(street), \(city), \(zipCode)"
        
        do {
            try viewContext.save()
            onCustomerCreated(newCustomer) // Pass the created customer back
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Failed to save customer: \(error.localizedDescription)")
        }
    }
    
    // Function to complete the address from search suggestions
    private func completeAddress(with completion: MKLocalSearchCompletion) {
        let originalStreet = street // Preserve the street number typed by the user

        // Perform a local search to get detailed information about the selected suggestion
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            if let result = response?.mapItems.first {
                let placemark = result.placemark
                
                // Retain street number if it's missing in the autocompleted result
                if let thoroughfare = placemark.thoroughfare, thoroughfare.range(of: "\\d", options: .regularExpression) == nil {
                    street = originalStreet + " " + thoroughfare
                } else {
                    street = placemark.thoroughfare ?? originalStreet
                }
                
                city = placemark.locality ?? city
                zipCode = placemark.postalCode ?? zipCode
                
                // Hide the search results once an address is selected
                searchResults = []
            }
        }
    }
}

// Delegate to handle search results
class SearchCompleterDelegate: NSObject, MKLocalSearchCompleterDelegate {
    var completionHandler: ([MKLocalSearchCompletion]) -> Void

    init(completionHandler: @escaping ([MKLocalSearchCompletion]) -> Void) {
        self.completionHandler = completionHandler
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completionHandler(completer.results)
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Error with search completer: \(error.localizedDescription)")
    }
}
