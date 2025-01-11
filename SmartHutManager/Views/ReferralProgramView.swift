//
//  ReferralProgramView.swift
//  SmartHutManager
//
//  Created by Darius Ogletree on 1/11/25.
//

import SwiftUI

struct ReferralProgramView: View {
    @State private var referralCode: String = "ABC123"
    @State private var rewardDetails: String = "10% Discount for both referrer and referee"

    var body: some View {
        VStack(spacing: 16) {
            Text("Referral Program")
                .font(.largeTitle)
                .bold()

            VStack(alignment: .leading, spacing: 8) {
                Text("Referral Code")
                    .font(.headline)
                Text(referralCode)
                    .font(.body)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
            }
            .padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                Text("Reward Details")
                    .font(.headline)
                Text(rewardDetails)
                    .font(.body)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
            }
            .padding(.horizontal)

            Button(action: shareReferralCode) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Referral Code")
                        .fontWeight(.bold)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
        .navigationTitle("Referral Program")
    }

    private func shareReferralCode() {
        // Logic to share referral code
        print("Referral code shared: \(referralCode)")
    }
}
