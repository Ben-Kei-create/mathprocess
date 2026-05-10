import Foundation

enum Grade: String, Codable, CaseIterable, Identifiable {
    case g1 = "中1"
    case g2 = "中2"
    case g3 = "中3"
    var id: String { rawValue }
}

enum UnitStatus: String, Codable {
    case available
    case comingSoon

    var label: String {
        switch self {
        case .available:  return "はじめる"
        case .comingSoon: return "準備中"
        }
    }
}

struct MathUnit: Codable, Identifiable, Hashable {
    let id: String
    let grade: Grade
    let title: String          // e.g. "一次方程式"
    let subtitle: String?      // short description
    let status: UnitStatus
    let order: Int

    var isAvailable: Bool { status == .available }
}
