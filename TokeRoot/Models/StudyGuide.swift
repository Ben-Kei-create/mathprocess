import Foundation

struct StudyGuide: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let unitId: String?
    let order: Int
    let steps: [StudyGuideStep]
}

struct StudyGuideStep: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let body: String
    let formula: String?
    let example: String?
}
