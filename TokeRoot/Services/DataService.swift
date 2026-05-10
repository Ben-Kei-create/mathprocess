import Foundation

/// Loads all bundled JSON content once at launch and exposes typed
/// in-memory collections. Pure read-only — write state lives in
/// `ProgressStore`.
@Observable
final class DataService {
    static let shared = DataService()

    private(set) var units: [MathUnit] = []
    private(set) var problems: [Problem] = []
    private(set) var practiceSets: [PracticeSet] = []
    private(set) var mistakeTags: [MistakeTag] = []
    private(set) var diagnosisProblems: [DiagnosisProblem] = []
    private(set) var homeMessages: HomeMessages = .empty
    private(set) var dailyWords: [String] = []
    private(set) var studyGuides: [StudyGuide] = []

    private init() { loadAll() }

    func loadAll() {
        units             = decode("units")                         ?? []
        let problemGroups: [[Problem]] = [
            decode("problems_g1_seifu")     ?? [],
            decode("problems_g1_mojishiki") ?? [],
            decode("problems_linear_eq")    ?? [],
            decode("problems_g1_hirei")     ?? [],
            decode("problems_g1_zukei")     ?? [],
            decode("problems_g2_shiki")     ?? [],
            decode("problems_g2_renritsu")  ?? [],
            decode("problems_g2_linear_fn") ?? [],
            decode("problems_g2_kakuritsu") ?? [],
            decode("problems_g3_tenkai")    ?? [],
            decode("problems_g3_heihokon")  ?? [],
            decode("problems_g3_quad_eq")   ?? [],
            decode("problems_g3_quad_fn")   ?? []
        ]
        problems          = problemGroups.flatMap { $0 }
        practiceSets      = decode("practice_sets")                 ?? []
        mistakeTags       = decode("mistake_tags")                  ?? []
        diagnosisProblems = decode("diagnosis_linear_eq")           ?? []
        homeMessages      = decode("home_messages")                 ?? .empty
        dailyWords        = decode("daily_words")                   ?? []
        studyGuides       = decode("study_guides")                  ?? []
    }

    // MARK: lookup helpers

    func unit(id: String) -> MathUnit? { units.first { $0.id == id } }
    func problem(id: String) -> Problem? { problems.first { $0.id == id } }
    func practiceSet(id: String) -> PracticeSet? { practiceSets.first { $0.id == id } }
    func mistakeTag(id: String) -> MistakeTag? { mistakeTags.first { $0.id == id } }

    /// Main learning sequence for a unit — excludes 特訓 sub-problems
    /// (those are reached via `practiceSet(id:)`).
    func problems(in unitId: String) -> [Problem] {
        problems.filter { $0.unitId == unitId && !$0.tags.contains("特訓") }
    }

    func diagnosis(for unitId: String) -> [DiagnosisProblem] {
        diagnosisProblems
            .filter { $0.unitId == unitId }
            .sorted { $0.order < $1.order }
    }

    func guides() -> [StudyGuide] {
        studyGuides.sorted { $0.order < $1.order }
    }

    func dailyWord(for date: Date = .now) -> String {
        guard !dailyWords.isEmpty else {
            return "今日の1問が、入試の日の自分を助けます。"
        }
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        return dailyWords[(dayOfYear - 1) % dailyWords.count]
    }

    // MARK: private

    private func decode<T: Decodable>(_ name: String) -> T? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}

struct HomeMessages: Codable {
    var comeback: [String]
    var shortTime: [String]
    var sportsBusy: [String]
    var lessonsBusy: [String]
    var stuck: [String]
    var progressing: [String]
    var `default`: [String]

    static let empty = HomeMessages(
        comeback: [], shortTime: [], sportsBusy: [], lessonsBusy: [],
        stuck: [], progressing: [], default: ["今日もここに来てくれてありがとうございます。"]
    )
}
