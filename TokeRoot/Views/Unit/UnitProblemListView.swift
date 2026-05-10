import SwiftUI

struct UnitProblemListView: View {
    let unitId: String

    @Environment(DataService.self) private var data
    @Environment(ProgressStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedTab: ProblemListTab = .active

    private typealias SectionDefinition = (
        id: String,
        title: String,
        caption: String,
        systemImage: String,
        include: (Problem) -> Bool
    )

    private enum ProblemListTab: String, CaseIterable, Identifiable {
        case active = "練習中"
        case completed = "完了"

        var id: String { rawValue }
    }

    private struct ProblemSection: Identifiable {
        let id: String
        let title: String
        let caption: String
        let systemImage: String
        let problems: [Problem]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TKSpacing.lg) {
                unitHeader

                Picker("表示", selection: $selectedTab) {
                    ForEach(ProblemListTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)

                if sections.isEmpty {
                    emptyState
                } else {
                    ForEach(sections) { section in
                        problemSection(section)
                    }
                }
            }
            .padding(.horizontal, TKSpacing.md)
            .padding(.top, TKSpacing.md)
            .padding(.bottom, TKSpacing.xl)
            .frame(maxWidth: horizontalSizeClass == .regular ? 780 : .infinity,
                   alignment: .topLeading)
            .frame(maxWidth: .infinity)
        }
        .background(TKColor.background.ignoresSafeArea())
        .navigationTitle(unit?.title ?? "問題")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var unitHeader: some View {
        VStack(alignment: .leading, spacing: TKSpacing.sm) {
            Text(unit?.title ?? "問題")
                .font(TKType.title)
                .foregroundStyle(TKColor.textPrimary)

            if let subtitle = unit?.subtitle {
                MathText(
                    text: subtitle,
                    font: TKType.body,
                    scriptFont: .system(size: 11, weight: .semibold, design: .rounded),
                    scriptOffset: 5
                )
                    .foregroundStyle(TKColor.textSecondary)
            }

            HStack(spacing: TKSpacing.sm) {
                summaryPill("\(activeCount)", caption: "練習中")
                summaryPill("\(masteredCount)", caption: "完了")
                summaryPill("\(problems.count)", caption: "類題")
            }

            ProgressView(value: Double(masteredCount),
                         total: Double(max(familyCount, 1)))
                .tint(TKColor.success)
        }
    }

    private func summaryPill(_ value: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value)
                .font(TKType.subtitle)
                .foregroundStyle(TKColor.textPrimary)
            Text(caption)
                .font(TKType.caption)
                .foregroundStyle(TKColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, TKSpacing.sm)
        .padding(.vertical, TKSpacing.sm)
        .background(TKColor.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: TKRadius.small))
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: TKSpacing.sm) {
            Text(emptyTitle)
                .font(TKType.subtitle)
                .foregroundStyle(TKColor.textPrimary)
            Text(emptyCaption)
                .font(TKType.body)
                .foregroundStyle(TKColor.textSecondary)
        }
        .padding(TKSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TKColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: TKRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: TKRadius.medium)
                .stroke(TKColor.divider, lineWidth: 1)
        )
    }

    private var emptyTitle: String {
        switch selectedTab {
        case .active: return "今はここに出す問題がありません。"
        case .completed: return "まだ完了した問題はありません。"
        }
    }

    private var emptyCaption: String {
        switch selectedTab {
        case .active:
            return "同じテーマの別の類題を3問クリアすると、完了へ移動します。"
        case .completed:
            return "類題を3問以上クリアしたテーマが、ここに移動します。"
        }
    }

    private func problemSection(_ section: ProblemSection) -> some View {
        VStack(alignment: .leading, spacing: TKSpacing.sm) {
            HStack(alignment: .center, spacing: TKSpacing.sm) {
                Image(systemName: section.systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(TKColor.accent)
                    .frame(width: 28, height: 28)
                    .background(TKColor.accentSoft)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(section.title)
                        .font(TKType.subtitle)
                        .foregroundStyle(TKColor.textPrimary)
                    Text(section.caption)
                        .font(TKType.caption)
                        .foregroundStyle(TKColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Text("\(section.problems.count)")
                    .font(TKType.caption)
                    .foregroundStyle(TKColor.textTertiary)
            }

            VStack(spacing: TKSpacing.sm) {
                ForEach(section.problems) { problem in
                    problemRow(problem)
                }
            }
        }
    }

    private func problemRow(_ problem: Problem) -> some View {
        NavigationLink(value: HomeView.NavTarget.problem(problem.id)) {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(difficultyColor(for: problem).opacity(0.82))
                    .frame(width: 5)

                HStack(alignment: .top, spacing: TKSpacing.md) {
                    if let icon = modeIcon(for: problem) {
                        Image(systemName: icon)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(difficultyColor(for: problem))
                            .frame(width: 34, height: 34)
                            .background(difficultyColor(for: problem).opacity(0.16))
                            .clipShape(RoundedRectangle(cornerRadius: TKRadius.small))
                    }

                    VStack(alignment: .leading, spacing: TKSpacing.xs) {
                        MathText(
                            text: problem.title,
                            font: TKType.subtitle,
                            scriptFont: .system(size: 12, weight: .semibold, design: .rounded),
                            scriptOffset: 6
                        )
                            .foregroundStyle(rowTextColor(for: problem))
                            .fixedSize(horizontal: false, vertical: true)

                        MathText(
                            text: problem.equation,
                            font: TKType.body,
                            scriptFont: .system(size: 11, weight: .semibold, design: .rounded),
                            scriptOffset: 5
                        )
                            .foregroundStyle(TKColor.textSecondary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)

                        HStack(spacing: TKSpacing.sm) {
                            masteryMarks(for: problem)
                            Spacer(minLength: TKSpacing.sm)
                            difficultyDots(for: problem)
                        }
                        .padding(.top, 2)
                    }

                    problemActionPill(for: problem)
                        .padding(.top, 5)
                }
                .padding(TKSpacing.md)
            }
            .background(rowBackground(for: problem))
            .clipShape(RoundedRectangle(cornerRadius: TKRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: TKRadius.medium)
                    .stroke(rowStroke(for: problem), lineWidth: 1)
            )
            .opacity(selectedTab == .completed ? 0.78 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel(for: problem))
    }

    private func problemActionPill(for problem: Problem) -> some View {
        let isCompleted = selectedTab == .completed
        return HStack(spacing: 5) {
            Text(isCompleted ? "もう一度" : "解く")
            Image(systemName: isCompleted ? "arrow.clockwise" : "chevron.right")
                .font(.system(size: 11, weight: .bold))
        }
        .font(TKType.caption)
        .foregroundStyle(.white)
        .lineLimit(1)
        .minimumScaleFactor(0.82)
        .padding(.horizontal, TKSpacing.sm)
        .padding(.vertical, 8)
        .frame(minWidth: 58)
        .background(isCompleted ? TKColor.textTertiary : difficultyColor(for: problem))
        .clipShape(Capsule())
        .shadow(color: difficultyColor(for: problem).opacity(isCompleted ? 0 : 0.18),
                radius: 5,
                y: 2)
    }

    private func masteryMarks(for problem: Problem) -> some View {
        let slots = store.familyMasterySlots(for: problem, data: data)
        return HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Image(systemName: index < slots ? "checkmark.square.fill" : "square")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(index < slots ? TKColor.success : TKColor.textTertiary.opacity(0.55))
            }
        }
    }

    private func difficultyDots(for problem: Problem) -> some View {
        HStack(spacing: 3) {
            ForEach(1...5, id: \.self) { value in
                Circle()
                    .fill(value <= problem.difficulty
                          ? difficultyColor(for: problem).opacity(0.82)
                          : TKColor.divider.opacity(0.75))
                    .frame(width: 6, height: 6)
            }
        }
        .accessibilityHidden(true)
    }

    private var unit: MathUnit? {
        data.unit(id: unitId)
    }

    private var problems: [Problem] {
        data.problems(in: unitId)
    }

    private var masteredCount: Int {
        store.masteredFamilyCount(in: unitId, data: data)
    }

    private var familyCount: Int {
        store.familyCount(in: unitId, data: data)
    }

    private var activeCount: Int {
        allSections.reduce(0) { total, section in
            total + activeProblems(in: section.problems).count
        }
    }

    private var sections: [ProblemSection] {
        allSections.compactMap { section in
            let filtered: [Problem]
            switch selectedTab {
            case .active:
                filtered = activeProblems(in: section.problems)
            case .completed:
                filtered = section.problems
                    .filter { store.isFamilyMastered(problem: $0, data: data) }
                    .sorted(by: problemSort)
            }

            guard !filtered.isEmpty else { return nil }
            return ProblemSection(
                id: section.id,
                title: section.title,
                caption: section.caption,
                systemImage: section.systemImage,
                problems: filtered
            )
        }
    }

    private func activeProblems(in problems: [Problem]) -> [Problem] {
        let candidates = Dictionary(grouping: problems, by: { store.familyKey(for: $0) })
            .values
            .compactMap { family -> Problem? in
                let sortedFamily = family.sorted(by: problemSort)
                guard let first = sortedFamily.first,
                      !store.isFamilyMastered(problem: first, data: data) else {
                    return nil
                }
                return nextVariant(in: sortedFamily)
            }
            .sorted(by: problemSort)

        guard let nextDifficulty = candidates.map(\.difficulty).min() else {
            return []
        }

        return candidates.filter { $0.difficulty == nextDifficulty }
    }

    private func nextVariant(in family: [Problem]) -> Problem? {
        family.first { store.clearCount(for: $0.id) == 0 } ?? family.first
    }

    private var allSections: [ProblemSection] {
        switch unitId {
        case "g1-seifu":
            return buildSections([
                ("number-line", "数の向きをつかむ", "0 より右か左か、距離はいくつかを確認します。", "arrow.left.and.right", {
                    containsAny(["数直線", "絶対値"], in: $0)
                }),
                ("add-subtract", "たし算・ひき算", "符号が混ざる計算を、向きで考えます。", "plus.forwardslash.minus", {
                    containsAny(["加法", "減法"], in: $0)
                }),
                ("multiply-divide", "かけ算・わり算", "まず符号、次に数の大きさを計算します。", "multiply", {
                    containsAny(["乗法", "除法", "累乗"], in: $0)
                })
            ])

        case "g1-mojishiki":
            return buildSections([
                ("write", "文字式の書き方", "かけ算記号を省くなど、書き方の基本です。", "pencil.line", {
                    containsAny(["書き方"], in: $0)
                }),
                ("like-terms", "同じ文字をまとめる", "同じ文字の前の数を整理します。", "tray.2", {
                    containsAny(["同類項"], in: $0)
                }),
                ("substitution", "文字に数を入れる", "文字の場所に数を入れて計算します。", "arrow.down.to.line", {
                    containsAny(["代入"], in: $0)
                }),
                ("modeling", "文章を式にする", "身近な場面を、文字を使った式にします。", "text.book.closed", {
                    containsAny(["式立て"], in: $0)
                }),
                ("distribute", "かっこを外す", "かっこの中に同じ数をかけます。", "rectangle.split.2x1", {
                    containsAny(["分配法則"], in: $0)
                })
            ])

        case "g1-linear-eq":
            return buildSections([
                ("basic", "まずは一手ずつ", "何を消すか、どちらに同じことをするかを確認します。", "1.circle", {
                    $0.mode == .nextMove
                    && $0.difficulty <= 2
                    && !containsAny(["文章題", "穴埋め", "自力"], in: $0)
                }),
                ("move-x", "x をまとめる", "両辺に x がある式を、片側に集めます。", "arrow.left.arrow.right", {
                    $0.mode == .nextMove
                    && $0.difficulty >= 3
                    && !containsAny(["文章題", "穴埋め", "自力"], in: $0)
                }),
                ("fill-in", "式を自分で入力する", "選ぶだけでなく、次の式を自分で書きます。", "keyboard", {
                    $0.mode == .fillIn || containsAny(["穴埋め"], in: $0)
                }),
                ("word", "文章題を式にする", "短い文を読んで、式を作ってから解きます。", "doc.text", {
                    containsAny(["文章題", "式立て"], in: $0)
                }),
                ("challenge", "自力チャレンジ", "途中式をメモしながら、最後の答えまで進みます。", "flag.checkered", {
                    $0.mode == .selfMade || containsAny(["自力"], in: $0)
                })
            ])

        case "g1-hirei":
            return buildSections([
                ("proportion", "比例の見方", "表と式で、同じ倍になる関係を見ます。", "arrow.up.right", {
                    containsAny(["比例"], in: $0)
                    && !containsAny(["反比例", "自力"], in: $0)
                }),
                ("inverse", "反比例の見方", "積が一定になる関係を、式と表で確認します。", "arrow.down.right", {
                    containsAny(["反比例"], in: $0)
                    && !containsAny(["自力"], in: $0)
                }),
                ("challenge", "自力チャレンジ", "途中式をメモして、最後の値まで出します。", "flag.checkered", {
                    $0.mode == .selfMade || containsAny(["自力"], in: $0)
                })
            ])

        case "g1-zukei":
            return buildSections([
                ("angle-name", "角の見方", "角の名前と、どこが頂点かを確認します。", "angle", {
                    containsAny(["角"], in: $0) && !containsAny(["角度"], in: $0)
                }),
                ("angle-size", "角度を求める", "180° などの決まりを使って x を求めます。", "triangle", {
                    containsAny(["角度"], in: $0)
                }),
                ("area", "面積を求める", "たて・横・高さを見て、公式につなげます。", "square.grid.3x3", {
                    containsAny(["面積"], in: $0)
                })
            ])

        case "g2-linear-fn":
            return buildSections([
                ("graph", "グラフを読む", "xy座標の直線から、傾きや切片を見ます。", "chart.xyaxis.line", {
                    containsAny(["グラフを読む"], in: $0)
                    && !containsAny(["自力"], in: $0)
                }),
                ("formula", "直線の式にする", "y = ax + b の形に戻します。", "function", {
                    containsAny(["式にする"], in: $0)
                    && !containsAny(["自力"], in: $0)
                }),
                ("challenge", "自力チャレンジ", "式とグラフを見ながら、自分で答えを出します。", "flag.checkered", {
                    $0.mode == .selfMade || containsAny(["自力"], in: $0)
                })
            ])

        case "g3-quad-fn":
            return buildSections([
                ("value", "値を出す", "x を入れて、y の値を落ち着いて計算します。", "number", {
                    containsAny(["値を出す"], in: $0)
                    && !containsAny(["自力"], in: $0)
                }),
                ("shape", "グラフの形", "上に開くか下に開くか、点の位置を見ます。", "chart.xyaxis.line", {
                    containsAny(["グラフの形"], in: $0)
                    && !containsAny(["自力"], in: $0)
                }),
                ("formula", "式にする", "点を式に入れて、a の値を求めます。", "function", {
                    containsAny(["式にする"], in: $0)
                    && !containsAny(["自力"], in: $0)
                }),
                ("rate", "変化の割合", "x と y の増え方から、変化の割合を出します。", "arrow.left.arrow.right", {
                    containsAny(["変化の割合"], in: $0)
                    && !containsAny(["自力"], in: $0)
                }),
                ("challenge", "自力チャレンジ", "途中式をメモして、最後の値まで自分で出します。", "flag.checkered", {
                    $0.mode == .selfMade || containsAny(["自力"], in: $0)
                })
            ])

        default:
            return buildSections([
                ("next-move", "えらんで進む", "次に何をするかを選びながら進みます。", "list.bullet", {
                    $0.mode == .nextMove
                }),
                ("fill-in", "式を入力する", "自分で次の式を書いて確認します。", "keyboard", {
                    $0.mode == .fillIn
                }),
                ("self-made", "自力で解く", "途中式をメモして答え合わせします。", "pencil.and.outline", {
                    $0.mode == .selfMade
                })
            ])
        }
    }

    private func buildSections(_ definitions: [SectionDefinition]) -> [ProblemSection] {
        var remaining = Set(problems.map(\.id))
        var result: [ProblemSection] = []

        for definition in definitions {
            let items = problems
                .filter { remaining.contains($0.id) && definition.include($0) }
                .sorted(by: problemSort)
            guard !items.isEmpty else { continue }

            result.append(ProblemSection(
                id: definition.id,
                title: definition.title,
                caption: definition.caption,
                systemImage: definition.systemImage,
                problems: items
            ))
            for item in items {
                remaining.remove(item.id)
            }
        }

        let uncategorized = problems
            .filter { remaining.contains($0.id) }
            .sorted(by: problemSort)
        if !uncategorized.isEmpty {
            result.append(ProblemSection(
                id: "other",
                title: "そのほか",
                caption: "続けて練習したい問題です。",
                systemImage: "ellipsis.circle",
                problems: uncategorized
            ))
        }

        return result
    }

    private func problemSort(_ lhs: Problem, _ rhs: Problem) -> Bool {
        if lhs.difficulty != rhs.difficulty {
            return lhs.difficulty < rhs.difficulty
        }
        return lhs.id < rhs.id
    }

    private func containsAny(_ tags: [String], in problem: Problem) -> Bool {
        tags.contains { problem.tags.contains($0) }
    }

    private func modeIcon(for problem: Problem) -> String? {
        switch problem.mode {
        case .nextMove: return nil
        case .fillIn: return "keyboard"
        case .selfMade: return "pencil.and.outline"
        }
    }

    private func difficultyColor(for problem: Problem) -> Color {
        switch problem.difficulty {
        case 1...2: return TKColor.success
        case 3: return TKColor.highlight
        case 4: return TKColor.warm
        default: return TKColor.accent
        }
    }

    private func rowBackground(for problem: Problem) -> Color {
        if selectedTab == .completed {
            return TKColor.surfaceElevated
        }
        return difficultyColor(for: problem).opacity(0.055)
    }

    private func rowStroke(for problem: Problem) -> Color {
        store.familyMasterySlots(for: problem, data: data) > 0
            ? difficultyColor(for: problem).opacity(0.28)
            : TKColor.divider
    }

    private func rowTextColor(for problem: Problem) -> Color {
        selectedTab == .completed ? TKColor.textSecondary : TKColor.textPrimary
    }

    private func accessibilityLabel(for problem: Problem) -> String {
        let count = store.familyMasterySlots(for: problem, data: data)
        let status = selectedTab == .completed ? "完了" : "類題\(count)問クリア"
        return "\(MathDisplayFormatter.plain(problem.title))、\(MathDisplayFormatter.plain(problem.equation))、\(status)"
    }
}
