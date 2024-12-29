import Foundation

@objc(BadgesTransformer)
class BadgesTransformer: ValueTransformer {

    override class func allowsReverseTransformation() -> Bool {
        return true
    }

    override class func transformedValueClass() -> AnyClass {
        return NSData.self
    }

    override func transformedValue(_ value: Any?) -> Any? {
        guard let badges = value as? [String] else {
            debugPrint("Failed to encode: Invalid badges object")
            return nil
        }
        let encoder = JSONEncoder()
        do {
            let encodedData = try encoder.encode(badges)
            // Log only during debugging
            #if DEBUG
            debugPrint("Successfully encoded badges data")
            #endif
            return encodedData
        } catch {
            debugPrint("Failed to encode badges: \(error.localizedDescription)")
            return nil
        }
    }

    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else {
            debugPrint("Failed to decode: No data available")
            return nil
        }
        let decoder = JSONDecoder()
        do {
            let decodedBadges = try decoder.decode([String].self, from: data)
            // Log only during debugging
            #if DEBUG
            debugPrint("Successfully decoded badges: \(decodedBadges)")
            #endif
            return decodedBadges
        } catch {
            debugPrint("Failed to decode badges: \(error.localizedDescription)")
            return nil
        }
    }
}
