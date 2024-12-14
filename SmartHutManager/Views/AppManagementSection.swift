//
//  AppManagementSection.swift
//  SmartHutManager
//
//  Created by Darius Ogletree on 12/14/24.
//

import SwiftUI

func appManagementSection() -> some View {
    Section(header: Text("App Management")) {
        NavigationLink(destination: ManageJobCategoriesView()) {
            SettingsItem(icon: "folder.fill", title: "Manage Job Categories", color: .orange)
        }
        SettingsItem(icon: "creditcard.fill", title: "Manage Payment Methods", color: .green)
        SettingsItem(icon: "bell.fill", title: "Notification Settings", color: .blue)
    }
}
