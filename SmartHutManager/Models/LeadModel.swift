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

    // Firestore requires a coding key for custom mapping if needed
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
    }
}
