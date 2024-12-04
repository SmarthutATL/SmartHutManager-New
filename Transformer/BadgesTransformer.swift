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
            print("Failed to encode: Invalid badges object")
            return nil
        }
        let encoder = JSONEncoder()
        do {
            let encodedData = try encoder.encode(badges)
            print("Successfully encoded badges data")
            return encodedData
        } catch {
            print("Failed to encode badges: \(error.localizedDescription)")
            return nil
        }
    }

    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else {
            print("Failed to decode: No data available")
            return nil
        }
        let decoder = JSONDecoder()
        do {
            let decodedBadges = try decoder.decode([String].self, from: data)
            print("Successfully decoded badges: \(decodedBadges)")
            return decodedBadges
        } catch {
            print("Failed to decode badges: \(error.localizedDescription)")
            return nil
        }
    }
}
