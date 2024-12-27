import SwiftUI
import FirebaseFirestore

struct EditTradesmanView: View {
    @ObservedObject var tradesman: Tradesmen // CoreData model instance

    @State private var name: String
    @State private var jobTitle: String
    @State private var phoneNumber: String
    @State private var address: String
    @State private var email: String

    @State private var isSaving = false
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode

    private let db = Firestore.firestore()

    init(tradesman: Tradesmen) {
        self.tradesman = tradesman
        self._name = State(initialValue: tradesman.name ?? "")
        self._jobTitle = State(initialValue: tradesman.jobTitle ?? "")
        self._phoneNumber = State(initialValue: tradesman.phoneNumber ?? "")
        self._address = State(initialValue: tradesman.address ?? "")
        self._email = State(initialValue: tradesman.email ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Edit Tradesman Info")) {
                    TextField("Full Name", text: $name)
                    TextField("Job Title", text: $jobTitle)
                    TextField("Phone Number", text: $phoneNumber)
                    TextField("Address", text: $address)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }

                if isSaving {
                    ProgressView("Saving...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    Button("Save Changes") {
                        saveChanges()
                    }
                    .disabled(
                        name.isEmpty ||
                        jobTitle.isEmpty ||
                        phoneNumber.isEmpty ||
                        address.isEmpty ||
                        email.isEmpty
                    )
                }
            }
            .navigationTitle("Edit Tradesman")
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }

    private func saveChanges() {
        isSaving = true

        // Update CoreData model
        tradesman.name = name
        tradesman.jobTitle = jobTitle
        tradesman.phoneNumber = phoneNumber
        tradesman.address = address
        tradesman.email = email

        // Save to CoreData
        do {
            try viewContext.save()
            print("Tradesman saved to CoreData.")
        } catch {
            print("Failed to save tradesman to CoreData: \(error.localizedDescription)")
        }

        // Update Firestore
        let tradesmanId = tradesman.objectID.uriRepresentation().absoluteString
        let updatedData: [String: Any] = [
            "name": name,
            "jobTitle": jobTitle,
            "phoneNumber": phoneNumber,
            "address": address,
            "email": email
        ]

        db.collection("tradesmen").document(tradesmanId).setData(updatedData, merge: true) { error in
            DispatchQueue.main.async {
                self.isSaving = false
                if let error = error {
                    print("Failed to save tradesman to Firestore: \(error.localizedDescription)")
                } else {
                    print("Tradesman updated successfully in Firestore.")
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}
