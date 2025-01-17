import Foundation
import FirebaseFirestore

struct Lead: Identifiable, Codable {
    var id: String? = UUID().uuidString // Optional, generated manually
    var name: String
    var email: String
    var phone: String
    var pipelineStage: String
    var score: Int
    var lastActivity: Date
    var notes: String
    var createdAt: Date
    var direct: Bool

    // Firestore requires custom coding keys for mapping fields
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case phone
        case pipelineStage
        case score
        case lastActivity
        case notes
        case createdAt
        case direct
    }
}
