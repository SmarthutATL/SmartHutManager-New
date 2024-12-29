import Foundation

@objc(MaterialItemTransformer)
class MaterialItemTransformer: ValueTransformer {

    override class func allowsReverseTransformation() -> Bool {
        return true
    }

    override class func transformedValueClass() -> AnyClass {
        return NSData.self
    }

    override func transformedValue(_ value: Any?) -> Any? {
        guard let materials = value as? [Material] else {
            debugPrint("Failed to encode: Invalid materials object")
            return nil
        }
        let encoder = JSONEncoder()
        do {
            let encodedData = try encoder.encode(materials)
            // Log only during debugging
            #if DEBUG
            debugPrint("Successfully encoded materials data")
            #endif
            return encodedData
        } catch {
            debugPrint("Failed to encode materials: \(error.localizedDescription)")
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
            let decodedMaterials = try decoder.decode([Material].self, from: data)
            // Log only during debugging
            #if DEBUG
            debugPrint("Successfully decoded materials: \(decodedMaterials)")
            #endif
            return decodedMaterials
        } catch {
            debugPrint("Failed to decode materials: \(error.localizedDescription)")
            return nil
        }
    }
}
