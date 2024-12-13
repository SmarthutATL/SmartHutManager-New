//
//  CreateTradesmenView.swift
//  SmartHutManager
//
//  Created by Darius Ogletree on 12/12/24.
//

import SwiftUI
import CoreData

struct CreateTradesmanView: View {
    @State private var name = ""
    @State private var jobTitle = ""
    @State private var phoneNumber = ""
    @State private var address = ""
    @State private var email = ""

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Tradesman Info")) {
                    TextField("Full Name", text: $name)
                    TextField("Job Title", text: $jobTitle)
                    TextField("Phone Number", text: $phoneNumber)
                    TextField("Address", text: $address)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }

                Button("Create Tradesman") {
                    let newTradesman = Tradesmen(context: viewContext)
                    newTradesman.name = name
                    newTradesman.jobTitle = jobTitle
                    newTradesman.phoneNumber = phoneNumber
                    newTradesman.address = address
                    newTradesman.email = email

                    do {
                        try viewContext.save()
                        presentationMode.wrappedValue.dismiss()
                    } catch {
                        print("Failed to save tradesman: \(error.localizedDescription)")
                    }
                }
                .disabled(name.isEmpty || jobTitle.isEmpty || phoneNumber.isEmpty || address.isEmpty || email.isEmpty)
            }
            .navigationTitle("Create Tradesman")
        }
    }
}
