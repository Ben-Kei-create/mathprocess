import Foundation

/// Local answer checker for short final-answer inputs.
///
/// This intentionally checks only the answer value, not the whole handwritten
/// process. A future AI checker can replace this service without changing the
/// self-made problem UI.
struct AnswerJudgeService {
    static let shared = AnswerJudgeService()

    func isCorrect(_ submittedAnswer: String, for problem: Problem) -> Bool {
        isCorrect(submittedAnswer, expectedAnswers: expectedAnswers(for: problem))
    }

    func isCorrect(_ submittedAnswer: String, expectedAnswers: [String]) -> Bool {
        let submitted = normalizedExpression(submittedAnswer)
        let submittedValue = answerSide(from: submitted)
        let submittedNumber = number(from: submittedValue)

        return expectedAnswers.contains { expected in
            let normalizedExpected = normalizedExpression(expected)
            if submitted == normalizedExpected { return true }

            let expectedValue = answerSide(from: normalizedExpected)
            if submittedValue == expectedValue { return true }

            if let submittedNumber,
               let expectedNumber = number(from: expectedValue) {
                return abs(submittedNumber - expectedNumber) < 0.000_001
            }
            return false
        }
    }

    private func expectedAnswers(for problem: Problem) -> [String] {
        var answers = [problem.finalAnswer]
        answers.append(contentsOf: problem.steps.flatMap { step in
            step.choices.filter(\.isCorrect).map(\.label)
        })
        return Array(Set(answers))
    }

    private func normalizedExpression(_ value: String) -> String {
        let halfWidth = value.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? value
        let normalized = halfWidth
            .replacingOccurrences(of: "＝", with: "=")
            .replacingOccurrences(of: "−", with: "-")
            .replacingOccurrences(of: "ー", with: "-")
            .replacingOccurrences(of: "²", with: "^2")
            .replacingOccurrences(of: "³", with: "^3")
            .replacingOccurrences(of: "½", with: "1/2")
            .replacingOccurrences(of: "です", with: "")
            .replacingOccurrences(of: "。", with: "")
            .replacingOccurrences(of: "、", with: "")
            .lowercased()
        return normalized
            .replacingOccurrences(of: "平方センチメートル", with: "")
            .replacingOccurrences(of: "cm^2", with: "")
            .replacingOccurrences(of: "cm2", with: "")
            .replacingOccurrences(of: "cm²", with: "")
            .replacingOccurrences(of: "㎠", with: "")
            .filter { !$0.isWhitespace && !$0.isNewline }
    }

    private func answerSide(from expression: String) -> String {
        guard let equalsIndex = expression.lastIndex(of: "=") else {
            return expression
        }
        return String(expression[expression.index(after: equalsIndex)...])
    }

    private func number(from value: String) -> Double? {
        let cleaned = value
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "°", with: "")
            .replacingOccurrences(of: "度", with: "")
        if cleaned.contains("/") {
            let parts = cleaned.split(separator: "/", maxSplits: 1).map(String.init)
            guard parts.count == 2,
                  let numerator = Double(parts[0]),
                  let denominator = Double(parts[1]),
                  denominator != 0 else {
                return nil
            }
            return numerator / denominator
        }
        return Double(cleaned)
    }
}
