import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct RegisterAdminView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var companyName = ""
    @State private var industryInput = ""
    @State private var selectedIndustries: [String] = []
    @State private var phoneNumber = ""
    @State private var address = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @Environment(\.presentationMode) var presentationMode

    let industrySuggestions = [
        "Handyman", "Home Automation", "Dog Grooming", "Bakery", "Fire Inspection", "Home Inspection",
        "Pressure Washing", "Technology", "Construction", "Healthcare", "Education", "Retail", "Finance", "Other",
        "Landscaping", "Pest Control", "Plumbing", "Electrical Services", "Carpentry", "Roofing", "HVAC", "Painting",
        "Interior Design", "Event Planning", "Catering", "Fitness Training", "Photography", "Videography",
        "Graphic Design", "Web Development", "App Development", "Cleaning Services", "Transportation", "Logistics",
        "Legal Services", "Accounting", "Consulting", "Real Estate", "Property Management", "Social Media Management",
        "Marketing", "Advertising", "Tutoring", "Translation Services", "Writing/Editing", "Music Production",
        "Artisanal Crafts", "Tailoring", "Fashion Design", "Barber Shop", "Salon Services", "Massage Therapy",
        "Tattoo Artist", "Pet Sitting", "Veterinary Services", "Auto Repair", "Mechanic Services", "Car Detailing",
        "Chimney Sweeping", "Dry Cleaning", "Waste Management", "Waterproofing Services", "Window Installation",
        "Door Installation", "Gutter Cleaning", "Power Washing", "Tree Services", "Snow Removal", "Security Services",
        "Cybersecurity", "IT Support", "Mobile Repair", "Courier Services", "Hospitality", "Hotel Management",
        "Travel Agency", "Tour Guide", "Personal Shopping", "Life Coaching", "Mental Health Counseling",
        "Physical Therapy", "Speech Therapy", "Nursing", "Childcare", "Elderly Care", "Pet Training", "Bicycle Repair",
        "Florist", "Jewelry Design", "Soap Making", "Candle Making", "Custom Furniture", "Craft Brewery", "Winery",
        "Farming", "Aquaponics", "Fishing", "Forestry", "Food Truck"
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Personal Details
                    Group {
                        TextField("First Name", text: $firstName)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                            .autocapitalization(.words)

                        TextField("Last Name", text: $lastName)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                            .autocapitalization(.words)

                        TextField("Email Address", text: $email)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)

                        SecureField("Password", text: $password)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)

                        SecureField("Confirm Password", text: $confirmPassword)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                    }

                    // Industry Selection Section
                    Group {
                        Text("Select or Add Your Industry (Up to 2)")
                            .font(.headline)
                            .padding(.top, 20)

                        TextField("Type to search or add industry", text: $industryInput, onCommit: addCustomIndustry)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                            .autocapitalization(.words)

                        // Display Suggestions
                        if !industryInput.isEmpty {
                            ScrollView(.vertical, showsIndicators: false) {
                                ForEach(filteredSuggestions(), id: \.self) { suggestion in
                                    Button(action: {
                                        addIndustry(suggestion)
                                    }) {
                                        Text(suggestion)
                                            .padding()
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(Color(UIColor.systemGray6))
                                            .cornerRadius(10)
                                    }
                                }
                            }
                            .frame(maxHeight: 150)
                        }

                        // Display Selected Industries
                        if !selectedIndustries.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Selected Industries:")
                                    .font(.subheadline)
                                    .fontWeight(.bold)

                                ForEach(selectedIndustries, id: \.self) { industry in
                                    HStack {
                                        Text(industry)
                                        Spacer()
                                        Button(action: {
                                            removeIndustry(industry)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                        }
                                    }
                                    .padding()
                                    .background(Color(UIColor.systemGray5))
                                    .cornerRadius(10)
                                }
                            }
                        }
                    }

                    // Business Details
                    Group {
                        TextField("Company Name", text: $companyName)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)

                        TextField("Phone Number", text: $phoneNumber)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                            .keyboardType(.phonePad)

                        TextField("Business Address", text: $address)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                    }

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.top, 10)
                    }

                    // Register Button
                    Button(action: registerAdmin) {
                        Text(isLoading ? "Registering..." : "Register Admin")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid() ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.top, 20)
                    }
                    .disabled(!isFormValid())

                    Spacer()
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Register Admin")
        }
    }

    // MARK: - Industry Management
    private func addIndustry(_ industry: String) {
        guard selectedIndustries.count < 2, !selectedIndustries.contains(industry) else { return }
        selectedIndustries.append(industry)
        industryInput = ""
    }

    private func addCustomIndustry() {
        let trimmedInput = industryInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else { return }
        addIndustry(trimmedInput)
    }

    private func removeIndustry(_ industry: String) {
        selectedIndustries.removeAll { $0 == industry }
    }

    private func filteredSuggestions() -> [String] {
        industrySuggestions.filter {
            $0.lowercased().contains(industryInput.lowercased())
        }
    }

    // MARK: - Registration Logic
    private func registerAdmin() {
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }

        isLoading = true
        let db = Firestore.firestore()

        // Generate a unique companyID
        generateUniqueCompanyID { uniqueCompanyID in
            guard let companyID = uniqueCompanyID else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to generate a unique Company ID. Please try again."
                    self.isLoading = false
                }
                return
            }

            Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.errorMessage = "Authentication Error: \(error.localizedDescription)"
                        self.isLoading = false
                        return
                    }

                    guard let userID = authResult?.user.uid else {
                        self.errorMessage = "Unexpected error: User ID is nil."
                        self.isLoading = false
                        return
                    }

                    // Save admin details to Firestore
                    db.collection("users").document(userID).setData([
                        "email": email,
                        "role": "admin",
                        "companyID": companyID,
                        "firstName": firstName,
                        "lastName": lastName,
                        "companyName": companyName,
                        "industries": selectedIndustries,
                        "phoneNumber": phoneNumber,
                        "address": address,
                        "createdAt": FieldValue.serverTimestamp() // Save timestamp
                    ]) { error in
                        DispatchQueue.main.async {
                            self.isLoading = false
                            if let error = error {
                                self.errorMessage = "Firestore Error: \(error.localizedDescription)"
                            } else {
                                self.presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }
                }
            }
        }
    }

    private func generateUniqueCompanyID(completion: @escaping (String?) -> Void) {
        let db = Firestore.firestore()
        let newCompanyID = UUID().uuidString.prefix(8).uppercased()

        db.collection("users").whereField("companyID", isEqualTo: newCompanyID).getDocuments { snapshot, error in
            if let error = error {
                print("Error checking companyID uniqueness: \(error.localizedDescription)")
                completion(nil)
                return
            }

            if snapshot?.isEmpty == true {
                // Company ID is unique
                completion(String(newCompanyID))
            } else {
                // Retry if collision detected
                generateUniqueCompanyID(completion: completion)
            }
        }
    }

    private func isFormValid() -> Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !companyName.isEmpty &&
        !selectedIndustries.isEmpty &&
        password == confirmPassword
    }
}
