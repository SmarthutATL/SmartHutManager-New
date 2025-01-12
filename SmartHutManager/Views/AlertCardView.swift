//
//  AlertCardView.swift
//  SmartHutManager
//
//  Created by Darius Ogletree on 1/12/25.
//

import SwiftUI

struct AlertCardView: View {
    let alert: AppAlert

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(alert.message ?? "No message")
                    .font(.body)
                    .foregroundColor(alert.isNew ? .blue : .primary)
                Spacer()
                if alert.isNew {
                    Text("NEW")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
            }

            if let timestamp = alert.timestamp {
                Text(timestamp, style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 4)
        )
    }
}
