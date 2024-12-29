//
//  ConfirmationSlider.swift
//  SmartHutManager
//
//  Created by Darius Ogletree on 12/28/24.
//

import Foundation
import SwiftUICore
import SwiftUI

struct ConfirmationSlider: View {
    @State private var offset: CGFloat = 0
    private let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.red.opacity(0.2))
                .frame(height: 50)

            Text("Slide to Delete")
                .foregroundColor(.red)
                .opacity(1 - Double(offset / UIScreen.main.bounds.width))

            HStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: 50, height: 50)
                    .offset(x: offset)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                offset = max(0, min(gesture.translation.width, UIScreen.main.bounds.width - 60))
                            }
                            .onEnded { _ in
                                if offset > UIScreen.main.bounds.width * 0.6 {
                                    action()
                                }
                                offset = 0 // Reset slider position
                            }
                    )

                Spacer()
            }
        }
        .frame(height: 50)
    }
}
