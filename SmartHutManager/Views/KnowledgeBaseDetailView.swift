//
//  KnowledgeBaseDetailView.swift
//  SmartHutManager
//
//  Created by Darius Ogletree on 1/17/25.
//

import SwiftUI

struct KnowledgeBaseDetailView: View {
    let question: String
    let answer: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(question)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.leading)
                
                Divider()
                
                Text(answer)
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
