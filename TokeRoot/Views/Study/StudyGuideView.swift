import SwiftUI

struct StudyGuideView: View {
    @Environment(DataService.self) private var data

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: TKSpacing.lg) {
                    header

                    VStack(spacing: TKSpacing.sm) {
                        ForEach(data.guides()) { guide in
                            NavigationLink(value: guide) {
                                StudyGuideSelectionRow(guide: guide)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, TKSpacing.md)
                .padding(.top, TKSpacing.md)
                .padding(.bottom, TKSpacing.xl)
            }
            .background(TKColor.background.ignoresSafeArea())
            .navigationTitle("勉強")
            .navigationDestination(for: StudyGuide.self) { guide in
                StudyGuideDetailView(guide: guide)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: TKSpacing.xs) {
            Text("読むだけで整理")
                .font(TKType.title)
                .foregroundStyle(TKColor.textPrimary)
            Text("単元を選んで、必要なところだけ読めます。")
                .font(TKType.body)
                .foregroundStyle(TKColor.textSecondary)
        }
    }
}

private struct StudyGuideSelectionRow: View {
    let guide: StudyGuide

    var body: some View {
        VStack(alignment: .leading, spacing: TKSpacing.lg) {
            HStack(alignment: .center, spacing: TKSpacing.md) {
                Image(systemName: "doc.text")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(TKColor.accent)
                    .frame(width: 38, height: 38)
                    .background(TKColor.accentSoft)
                    .clipShape(RoundedRectangle(cornerRadius: TKRadius.small))

                VStack(alignment: .leading, spacing: 3) {
                    MathText(
                        text: guide.title,
                        font: TKType.subtitle,
                        scriptFont: .system(size: 12, weight: .semibold, design: .rounded),
                        scriptOffset: 6
                    )
                        .foregroundStyle(TKColor.textPrimary)
                    MathText(
                        text: guide.subtitle,
                        font: TKType.caption,
                        scriptFont: .system(size: 9, weight: .semibold, design: .rounded),
                        scriptOffset: 4
                    )
                        .foregroundStyle(TKColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(guide.steps.count)章")
                        .font(TKType.caption)
                        .foregroundStyle(TKColor.textTertiary)
                }

                Spacer()

                HStack(spacing: 5) {
                    Text("開く")
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                }
                .font(TKType.caption)
                .foregroundStyle(.white)
                .padding(.horizontal, TKSpacing.sm)
                .padding(.vertical, 8)
                .background(TKColor.accent)
                .clipShape(Capsule())
            }
        }
        .padding(TKSpacing.md)
        .background(TKColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: TKRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: TKRadius.medium)
                .stroke(TKColor.divider, lineWidth: 1)
        )
        .shadow(color: TKColor.accent.opacity(0.06), radius: 6, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(MathDisplayFormatter.plain(guide.title))、\(MathDisplayFormatter.plain(guide.subtitle))、\(guide.steps.count)章、開く")
    }
}

private struct StudyGuideDetailView: View {
    let guide: StudyGuide

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: TKSpacing.xl) {
                    articleHeader
                    tableOfContents(proxy: proxy)

                    ForEach(Array(guide.steps.enumerated()), id: \.element.id) { index, step in
                        StudyGuideStepArticle(step: step, index: index + 1)
                            .id(step.id)
                    }
                }
                .padding(.horizontal, TKSpacing.md)
                .padding(.top, TKSpacing.md)
                .padding(.bottom, TKSpacing.xl)
            }
            .background(TKColor.background.ignoresSafeArea())
        }
        .navigationTitle(guide.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var articleHeader: some View {
        VStack(alignment: .leading, spacing: TKSpacing.sm) {
            MathText(
                text: guide.title,
                font: TKType.title,
                scriptFont: .system(size: 16, weight: .semibold, design: .rounded),
                scriptOffset: 8
            )
                .foregroundStyle(TKColor.textPrimary)
            MathText(
                text: guide.subtitle,
                font: TKType.body,
                scriptFont: .system(size: 11, weight: .semibold, design: .rounded),
                scriptOffset: 5
            )
                .foregroundStyle(TKColor.textSecondary)
        }
    }

    private func tableOfContents(proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: TKSpacing.sm) {
            Text("目次")
                .font(TKType.subtitle)
                .foregroundStyle(TKColor.textPrimary)

            VStack(spacing: 0) {
                ForEach(Array(guide.steps.enumerated()), id: \.element.id) { index, step in
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            proxy.scrollTo(step.id, anchor: .top)
                        }
                    } label: {
                        HStack(alignment: .firstTextBaseline, spacing: TKSpacing.sm) {
                            Text("\(index + 1)")
                                .font(TKType.caption)
                                .foregroundStyle(TKColor.accent)
                                .frame(width: 22, alignment: .leading)
                            MathText(
                                text: step.title,
                                font: TKType.body,
                                scriptFont: .system(size: 11, weight: .semibold, design: .rounded),
                                scriptOffset: 5
                            )
                                .foregroundStyle(TKColor.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(TKColor.textTertiary)
                        }
                        .padding(.vertical, TKSpacing.sm)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if index < guide.steps.count - 1 {
                        Divider()
                            .background(TKColor.divider)
                    }
                }
            }
            .padding(.horizontal, TKSpacing.md)
            .padding(.vertical, TKSpacing.xs)
            .background(TKColor.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: TKRadius.small))
        }
    }
}

private struct StudyGuideStepArticle: View {
    let step: StudyGuideStep
    let index: Int

    var body: some View {
        VStack(alignment: .leading, spacing: TKSpacing.md) {
            HStack(alignment: .firstTextBaseline, spacing: TKSpacing.sm) {
                Text("\(index)")
                    .font(TKType.caption)
                    .foregroundStyle(TKColor.accent)
                    .frame(width: 24, alignment: .leading)

                MathText(
                    text: step.title,
                    font: TKType.subtitle,
                    scriptFont: .system(size: 12, weight: .semibold, design: .rounded),
                    scriptOffset: 6
                )
                    .foregroundStyle(TKColor.textPrimary)
            }

            MathText(
                text: step.body,
                font: TKType.body,
                scriptFont: .system(size: 11, weight: .semibold, design: .rounded),
                scriptOffset: 5
            )
                .foregroundStyle(TKColor.textPrimary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            if let formula = step.formula {
                FormulaBlock(formula: formula)
            }

            if let example = step.example {
                ExampleBlock(example: example)
            }
        }
        .padding(.bottom, TKSpacing.md)
        .overlay(alignment: .bottom) {
            Divider()
                .background(TKColor.divider)
        }
    }
}

private struct FormulaBlock: View {
    let formula: String

    var body: some View {
        VStack(alignment: .leading, spacing: TKSpacing.xs) {
            Text("公式")
                .font(TKType.caption)
                .foregroundStyle(TKColor.accent)
            MathText(
                text: formula,
                font: TKType.subtitle,
                scriptFont: .system(size: 12, weight: .semibold, design: .rounded),
                scriptOffset: 6
            )
                .foregroundStyle(TKColor.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, TKSpacing.md)
        .padding(.vertical, TKSpacing.md)
        .background(TKColor.accentSoft.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: TKRadius.small))
        .overlay(
            RoundedRectangle(cornerRadius: TKRadius.small)
                .stroke(TKColor.accent.opacity(0.18), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}

private struct ExampleBlock: View {
    let example: String

    var body: some View {
        VStack(alignment: .leading, spacing: TKSpacing.xs) {
            Text("例")
                .font(TKType.caption)
                .foregroundStyle(TKColor.textTertiary)
            MathText(
                text: example,
                font: TKType.caption,
                scriptFont: .system(size: 9, weight: .semibold, design: .rounded),
                scriptOffset: 4
            )
                .foregroundStyle(TKColor.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(TKSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TKColor.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: TKRadius.small))
    }
}
