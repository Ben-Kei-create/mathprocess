import Foundation

/// Rule-based engine that decides:
///  - which `PracticeSet` to recommend after the diagnosis test
///  - which home message to show today
///  - what the "つづきから" target should be
///
/// All rules are deterministic and local — no AI in MVP.
struct RouteEngine {

    let data: DataService
    let store: ProgressStore

    init(data: DataService = .shared, store: ProgressStore = .shared) {
        self.data = data
        self.store = store
    }

    // MARK: Diagnosis -> recommendation

    func diagnose(answers: [String: String]) -> DiagnosisResult {
        let problems = data.diagnosis(for: "g1-linear-eq")
        var wrongTags: [String] = []
        var rightLabels: [String] = []

        for p in problems {
            let chosenId = answers[p.id]
            let correct = p.choices.first(where: { $0.isCorrect })?.id
            if chosenId == correct {
                rightLabels.append(strengthLabel(for: p))
            } else {
                wrongTags.append(p.mistakeTagIdIfWrong)
            }
        }

        let pickedTagId = wrongTags.first
            ?? "isolate-2x-to-x"   // fall-through default route start
        let setId = data.mistakeTag(id: pickedTagId)?.practiceSetId
            ?? "set-isolate-2x"

        let kind: String
        if wrongTags.isEmpty {
            kind = "ほとんどの基本ができています。最初の3問から軽くおさらいしましょう。"
        } else if rightLabels.isEmpty {
            kind = "ゆっくり進めば大丈夫です。最初の小さな一手からはじめましょう。"
        } else {
            let strengths = rightLabels.prefix(2).joined(separator: "・")
            let nextLabel = data.mistakeTag(id: pickedTagId)?.label ?? "次のステップ"
            kind = "「\(strengths)」はできています。次は「\(nextLabel)」から始めると良さそうです。"
        }

        return DiagnosisResult(
            unitId: "g1-linear-eq",
            strengths: rightLabels,
            recommendedPracticeSetId: setId,
            kindMessage: kind
        )
    }

    private func strengthLabel(for p: DiagnosisProblem) -> String {
        switch p.id {
        case "diag-le-1": return "+の数を消す"
        case "diag-le-2": return "2xをxにする"
        case "diag-le-3": return "+を消してから割る"
        case "diag-le-4": return "両辺にxがあるときの移項"
        case "diag-le-5": return "短い文を式にする"
        default:          return "基本"
        }
    }

    // MARK: Home message

    func todayHomeMessage() -> String {
        let m = data.homeMessages
        let minutes = store.profile.dailyTime.rawValue
        let dueCount = store.dueReviewItems().count

        if dueCount > 0 {
            return "今日は前に解けた問題を\(dueCount)問だけ確認しましょう。忘れる前に戻ると、ちゃんと残ります。"
        }

        if let days = store.daysSinceLastStudy(), days >= 2 {
            return pick(m.comeback)
                .replacingOccurrences(of: "{days}", with: "\(days)")
        }
        if let tagId = store.topStuckTagId(),
           let tag = data.mistakeTag(id: tagId) {
            return pick(m.stuck)
                .replacingOccurrences(of: "{tag}", with: tag.label)
                .replacingOccurrences(of: "{count}", with: "3")
        }
        switch store.profile.lifestyle {
        case .sportsClub:    return pick(m.sportsBusy)
        case .lessonsBusy:   return pick(m.lessonsBusy)
        default: break
        }
        if minutes <= 5 {
            return pick(m.shortTime)
                .replacingOccurrences(of: "{minutes}", with: "\(minutes)")
        }
        if !store.events.isEmpty {
            return pick(m.progressing)
                .replacingOccurrences(of: "{minutes}", with: "\(minutes)")
        }
        return pick(m.default)
    }

    private func pick(_ list: [String]) -> String {
        list.randomElement() ?? "今日もここに来てくれてありがとうございます。"
    }

    // MARK: Continue target

    /// What should the home 「つづきから」 button open?
    func continueTarget() -> ContinueTarget {
        if !store.profile.hasCompletedOnboarding {
            return .onboarding
        }
        if !store.profile.hasCompletedDiagnosis {
            return .diagnosis(unitId: "g1-linear-eq")
        }
        if let firstDueReview = store.dueReviewItems().first {
            return .problem(id: firstDueReview.problemId)
        }
        if let pid = store.lastProblemId,
           let _ = data.problem(id: pid) {
            return .problem(id: pid)
        }
        if let setId = store.profile.diagnosisRecommendedSetId,
           let set = data.practiceSet(id: setId),
           let firstId = set.problemIds.first {
            return .problem(id: firstId)
        }
        if let firstId = data.problems(in: "g1-linear-eq").first?.id {
            return .problem(id: firstId)
        }
        return .unitSelect
    }

    /// 「今日のおすすめ」 short caption.
    func todaysRecommendation() -> String {
        let dueCount = store.dueReviewItems().count
        if dueCount > 0 {
            return "復習 \(dueCount)問"
        }
        if let tagId = store.topStuckTagId(),
           let tag = data.mistakeTag(id: tagId),
           let set = data.practiceSet(id: tag.practiceSetId) {
            return "一次方程式：\(set.title) 3問"
        }
        if !store.profile.hasCompletedDiagnosis {
            return "ルート診断テスト（5問・約3分）"
        }
        return "一次方程式：基本ステップ 3問"
    }
}

enum ContinueTarget: Equatable {
    case onboarding
    case diagnosis(unitId: String)
    case problem(id: String)
    case unitSelect
}
