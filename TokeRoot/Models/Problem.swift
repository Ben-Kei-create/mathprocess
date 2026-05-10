import Foundation

/// One step within a problem. A step asks 「次に何をする？」 and offers
/// 2-4 choices, exactly one of which is correct. Wrong choices carry a
/// `mistakeTagId` so the app can route the user to focused practice.
struct ProblemStep: Codable, Identifiable, Hashable {
    let id: String
    let prompt: String                // e.g. "まず何をする？"
    let equationBefore: String        // shown in the card before this step
    let choices: [Choice]
    let explanationCaption: String    // shown when the step advances
    let equationAfter: String         // card after this step
    let highlight: String?            // substring to highlight (e.g. "-3")

    struct Choice: Codable, Identifiable, Hashable {
        let id: String
        let label: String
        let isCorrect: Bool
        let mistakeTagId: String?     // nil if correct
    }

    var correctChoice: Choice {
        choices.first(where: { $0.isCorrect }) ?? choices[0]
    }
}

/// The three solving modes the unit progresses through. MVP only ships
/// `.nextMove` but the data structure already accommodates the others.
enum SolveMode: String, Codable, CaseIterable {
    case nextMove = "次の一手モード"
    case fillIn   = "穴埋めモード"
    case selfMade = "自力モード"
}

struct Problem: Codable, Identifiable, Hashable {
    let id: String
    let unitId: String
    let familyId: String?
    let title: String                 // short label, optional
    let equation: String              // headline equation: "2x + 3 = 11"
    let diagram: GeometryDiagram?
    let graph: CartesianGraph?
    let mode: SolveMode
    let difficulty: Int               // 1...5
    let steps: [ProblemStep]
    let finalAnswer: String           // "x = 4"
    let hint: String                  // single calm hint
    let tags: [String]                // free-form tags ("移項", "係数")
}

/// Optional visual support for geometry problems. Coordinates are normalized
/// from 0...1 so the same JSON can render on iPhone and iPad.
struct GeometryDiagram: Codable, Hashable {
    let aspectRatio: Double
    let points: [GeometryPoint]
    let segments: [GeometrySegment]
    let angles: [GeometryAngle]
    let labels: [GeometryLabel]

    private enum CodingKeys: String, CodingKey {
        case aspectRatio
        case points
        case segments
        case angles
        case labels
    }

    init(
        aspectRatio: Double = 4.0 / 3.0,
        points: [GeometryPoint],
        segments: [GeometrySegment],
        angles: [GeometryAngle] = [],
        labels: [GeometryLabel] = []
    ) {
        self.aspectRatio = aspectRatio
        self.points = points
        self.segments = segments
        self.angles = angles
        self.labels = labels
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        aspectRatio = try container.decodeIfPresent(Double.self, forKey: .aspectRatio) ?? 4.0 / 3.0
        points = try container.decode([GeometryPoint].self, forKey: .points)
        segments = try container.decode([GeometrySegment].self, forKey: .segments)
        angles = try container.decodeIfPresent([GeometryAngle].self, forKey: .angles) ?? []
        labels = try container.decodeIfPresent([GeometryLabel].self, forKey: .labels) ?? []
    }
}

struct GeometryPoint: Codable, Identifiable, Hashable {
    let id: String
    let x: Double
    let y: Double
    let label: String?
}

struct GeometrySegment: Codable, Hashable {
    let start: String
    let end: String
}

struct GeometryAngle: Codable, Hashable {
    let vertex: String
    let radius: Double
    let startDegrees: Double
    let endDegrees: Double
}

struct GeometryLabel: Codable, Hashable {
    let text: String
    let x: Double
    let y: Double
}

/// A small coordinate-plane graph for functions such as y = ax + b.
struct CartesianGraph: Codable, Hashable {
    let xMin: Double
    let xMax: Double
    let yMin: Double
    let yMax: Double
    let parabolas: [CartesianParabola]
    let lines: [CartesianLine]
    let points: [CartesianPoint]

    private enum CodingKeys: String, CodingKey {
        case xMin
        case xMax
        case yMin
        case yMax
        case parabolas
        case lines
        case points
    }

    init(
        xMin: Double,
        xMax: Double,
        yMin: Double,
        yMax: Double,
        parabolas: [CartesianParabola] = [],
        lines: [CartesianLine] = [],
        points: [CartesianPoint] = []
    ) {
        self.xMin = xMin
        self.xMax = xMax
        self.yMin = yMin
        self.yMax = yMax
        self.parabolas = parabolas
        self.lines = lines
        self.points = points
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        xMin = try container.decode(Double.self, forKey: .xMin)
        xMax = try container.decode(Double.self, forKey: .xMax)
        yMin = try container.decode(Double.self, forKey: .yMin)
        yMax = try container.decode(Double.self, forKey: .yMax)
        parabolas = try container.decodeIfPresent([CartesianParabola].self, forKey: .parabolas) ?? []
        lines = try container.decodeIfPresent([CartesianLine].self, forKey: .lines) ?? []
        points = try container.decodeIfPresent([CartesianPoint].self, forKey: .points) ?? []
    }
}

struct CartesianParabola: Codable, Identifiable, Hashable {
    let id: String
    let label: String?
    let a: Double
    let h: Double
    let k: Double
    let xStart: Double
    let xEnd: Double

    private enum CodingKeys: String, CodingKey {
        case id
        case label
        case a
        case h
        case k
        case xStart
        case xEnd
    }

    init(
        id: String,
        label: String? = nil,
        a: Double,
        h: Double = 0,
        k: Double = 0,
        xStart: Double,
        xEnd: Double
    ) {
        self.id = id
        self.label = label
        self.a = a
        self.h = h
        self.k = k
        self.xStart = xStart
        self.xEnd = xEnd
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        label = try container.decodeIfPresent(String.self, forKey: .label)
        a = try container.decode(Double.self, forKey: .a)
        h = try container.decodeIfPresent(Double.self, forKey: .h) ?? 0
        k = try container.decodeIfPresent(Double.self, forKey: .k) ?? 0
        xStart = try container.decode(Double.self, forKey: .xStart)
        xEnd = try container.decode(Double.self, forKey: .xEnd)
    }
}

struct CartesianLine: Codable, Identifiable, Hashable {
    let id: String
    let label: String?
    let x1: Double
    let y1: Double
    let x2: Double
    let y2: Double
}

struct CartesianPoint: Codable, Identifiable, Hashable {
    let id: String
    let x: Double
    let y: Double
    let label: String?
}

/// A small targeted set used by 「ここだけ特訓」 and the recovery route.
struct PracticeSet: Codable, Identifiable, Hashable {
    let id: String
    let title: String                 // "2xをxにする練習"
    let mistakeTagId: String
    let problemIds: [String]
}
