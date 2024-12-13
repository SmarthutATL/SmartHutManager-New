//
//  EditTradesmenView.swift
//  SmartHutManager
//
//  Created by Darius Ogletree on 12/12/24.
//

import SwiftUI
import CoreData

struct EditTradesmanView: View {
    @ObservedObject var tradesman: Tradesmen

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Edit Tradesman Info")) {
                    TextField("Full Name", text: Binding(
                        get: { tradesman.name ?? "" },
                        set: { tradesman.name = $0 }
                    ))
                    TextField("Job Title", text: Binding(
                        get: { tradesman.jobTitle ?? "" },
                        set: { tradesman.jobTitle = $0 }
                    ))
                    TextField("Phone Number", text: Binding(
                        get: { tradesman.phoneNumber ?? "" },
                        set: { tradesman.phoneNumber = $0 }
                    ))
                    TextField("Address", text: Binding(
                        get: { tradesman.address ?? "" },
                        set: { tradesman.address = $0 }
                    ))
                    TextField("Email", text: Binding(
                        get: { tradesman.email ?? "" },
                        set: { tradesman.email = $0 }
                    ))
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                }

                Button("Save Changes") {
                    do {
                        if viewContext.hasChanges {
                            try viewContext.save()
                        }
                        presentationMode.wrappedValue.dismiss()
                    } catch {
                        print("Failed to save tradesman: \(error.localizedDescription)")
                    }
                }
                .disabled(tradesman.name?.isEmpty ?? true || tradesman.jobTitle?.isEmpty ?? true || tradesman.phoneNumber?.isEmpty ?? true || tradesman.address?.isEmpty ?? true || tradesman.email?.isEmpty ?? true)
            }
            .navigationTitle("Edit Tradesman")
        }
    }
}
