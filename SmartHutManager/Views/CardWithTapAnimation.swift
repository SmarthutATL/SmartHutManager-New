//
//  CardWithTapAnimation.swift
//  SmartHutManager
//
//  Created by Darius Ogletree on 1/1/25.
//

import SwiftUI

// MARK: - CardWithTapAnimation Component
struct CardWithTapAnimation<Content: View>: View {
    @State private var isTapped: Bool = false // Independent state for each card
    let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            content()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
        )
        .scaleEffect(isTapped ? 0.97 : 1.0) // Scale effect for tap animation
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                isTapped = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isTapped = false
            }
        }
    }
}
