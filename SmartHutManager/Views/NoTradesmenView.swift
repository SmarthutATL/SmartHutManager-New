//
//  NoTradesmenView.swift
//  SmartHutManager
//
//  Created by Darius Ogletree on 12/2/24.
//

import SwiftUI

struct NoTradesmenView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.xmark")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.gray)

            Text("No Tradesmen Found")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.gray)

            Text("Please add tradesmen to view details.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
        }
        .padding()
        .navigationTitle("Tech Details")
    }
}
