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
            print("Failed to encode: Invalid materials object")
            return nil
        }
        let encoder = JSONEncoder()
        do {
            let encodedData = try encoder.encode(materials)
            print("Successfully encoded materials data")
            return encodedData
        } catch {
            print("Failed to encode materials: \(error.localizedDescription)")
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
            let decodedMaterials = try decoder.decode([Material].self, from: data)
            print("Successfully decoded materials: \(decodedMaterials)")
            return decodedMaterials
        } catch {
            print("Failed to decode materials: \(error.localizedDescription)")
            return nil
        }
    }
}
