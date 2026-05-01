import Foundation

enum DailyTime: Int, Codable, CaseIterable, Identifiable {
    case t3 = 3
    case t5 = 5
    case t10 = 10
    case t15 = 15
    case t20 = 20

    var id: Int { rawValue }
    var label: String { self == .t20 ? "20分以上" : "\(rawValue)分" }
    var goalSeconds: Int { rawValue * 60 }
}

enum Lifestyle: String, Codable, CaseIterable, Identifiable {
    case sportsClub      = "運動部で忙しい"
    case lessonsBusy     = "塾や習い事が多い"
    case someTimeAtHome  = "家で少し時間がある"
    case unsure          = "まだわからない"

    var id: String { rawValue }
}

struct UserProfile: Codable, Hashable {
    var dailyTime: DailyTime
    var lifestyle: Lifestyle
    var hasCompletedOnboarding: Bool
    var hasCompletedDiagnosis: Bool
    var diagnosisRecommendedSetId: String?
    var adsRemoved: Bool

    static let empty = UserProfile(
        dailyTime: .t5,
        lifestyle: .unsure,
        hasCompletedOnboarding: false,
        hasCompletedDiagnosis: false,
        diagnosisRecommendedSetId: nil,
        adsRemoved: false
    )
}
