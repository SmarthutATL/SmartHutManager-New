//
//  MaterialManager.swift
//  SmartHutManager
//
//  Created by Darius Ogletree on 12/2/24.
//

import FirebaseAuth
import FirebaseFirestore
import SwiftUI
import Foundation
import CoreData


struct Material: Identifiable, Codable {
    var id: UUID
    var name: String
    var price: Double
    var quantity: Int
    
    // Custom initializer to handle missing `quantity` during decoding
    init(id: UUID = UUID(), name: String, price: Double, quantity: Int = 1) {
        self.id = id
        self.name = name
        self.price = price
        self.quantity = quantity
    }
    
    // Custom decoding to provide a default quantity if missing
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.price = try container.decode(Double.self, forKey: .price)
        
        // Attempt to decode quantity, defaulting to 1 if not found
        self.quantity = try container.decodeIfPresent(Int.self, forKey: .quantity) ?? 1
    }
}
