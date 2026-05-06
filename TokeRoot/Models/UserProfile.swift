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
    var reminderHour: Int?
    var reminderMinute: Int?

    init(dailyTime: DailyTime,
         lifestyle: Lifestyle,
         hasCompletedOnboarding: Bool,
         hasCompletedDiagnosis: Bool,
         diagnosisRecommendedSetId: String?,
         adsRemoved: Bool,
         reminderHour: Int? = nil,
         reminderMinute: Int? = nil) {
        self.dailyTime = dailyTime
        self.lifestyle = lifestyle
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.hasCompletedDiagnosis = hasCompletedDiagnosis
        self.diagnosisRecommendedSetId = diagnosisRecommendedSetId
        self.adsRemoved = adsRemoved
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        dailyTime = try c.decode(DailyTime.self, forKey: .dailyTime)
        lifestyle = try c.decode(Lifestyle.self, forKey: .lifestyle)
        hasCompletedOnboarding = try c.decode(Bool.self, forKey: .hasCompletedOnboarding)
        hasCompletedDiagnosis = try c.decode(Bool.self, forKey: .hasCompletedDiagnosis)
        diagnosisRecommendedSetId = try c.decodeIfPresent(String.self, forKey: .diagnosisRecommendedSetId)
        adsRemoved = try c.decodeIfPresent(Bool.self, forKey: .adsRemoved) ?? false
        reminderHour = try c.decodeIfPresent(Int.self, forKey: .reminderHour)
        reminderMinute = try c.decodeIfPresent(Int.self, forKey: .reminderMinute)
    }

    static let empty = UserProfile(
        dailyTime: .t5,
        lifestyle: .unsure,
        hasCompletedOnboarding: false,
        hasCompletedDiagnosis: false,
        diagnosisRecommendedSetId: nil,
        adsRemoved: false,
        reminderHour: nil,
        reminderMinute: nil
    )
}
