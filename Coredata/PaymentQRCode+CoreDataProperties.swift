//
//  PaymentQRCode+CoreDataProperties.swift
//  SmartHutManager
//
//  Created by Darius Ogletree on 12/29/24.
//
//

import Foundation
import CoreData
import UIKit // Import UIKit to work with UIImage

extension PaymentQRCode {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PaymentQRCode> {
        return NSFetchRequest<PaymentQRCode>(entityName: "PaymentQRCode")
    }

    @NSManaged public var type: String?
    @NSManaged public var qrCode: Data?

    // Computed property to convert Data to UIImage and vice versa
    var qrCodeImage: UIImage? {
        get {
            guard let data = qrCode else { return nil }
            return UIImage(data: data)
        }
        set {
            qrCode = newValue?.pngData()
        }
    }
}

extension PaymentQRCode: Identifiable {

}
