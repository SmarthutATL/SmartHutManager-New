//
//  PaymentMethod.swift
//  SmartHutManager
//
//  Created by Darius Ogletree on 12/29/24.
//

import Foundation

enum PaymentMethod: String, CaseIterable, Identifiable {
    case applePay = "Apple Pay"
    case paypal = "PayPal"
    case zelle = "Zelle"
    case cash = "Cash"

    var id: String { self.rawValue }
}
