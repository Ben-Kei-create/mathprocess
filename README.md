# 解け√ルート (Toke Root)

Japanese middle-school math learning app — MVP prototype.

> 「解けないを、解けるルートに変える。」

## Concept

A calm, focused math recovery app for Japanese junior-high students.
Not a quiz app, not a camera-solver, not an AI tutor — a step-by-step
**route back to "I know what to do next."**

## MVP Scope

The prototype ships three 中1 units:

- **正負の数** — adding/subtracting/multiplying signed numbers
- **文字式** — coefficients, like-terms, distributive law, substitution
- **一次方程式** — Lv.1 一手の移項 → Lv.5 両辺カッコ・分数・文章題

The data model and navigation are designed so future units (一次関数,
二次方程式, 三平方の定理, …) plug in without redesign — drop a new JSON
file and a row in `units.json`.

All problems, hints, mistake tags, recovery sets and step-by-step
explanations are **local structured data** (JSON + Swift models). No
generative AI in the MVP.

## Stack

- SwiftUI (iOS 17+)
- Swift 5.9 / @Observable view models
- `UserDefaults` + JSON-encoded snapshot for persistence
- PencilKit for the handwritten memo sheet
- No third-party dependencies

## Project layout

```
mathprocess.xcodeproj/
mathprocess/
  App/             TokeRootApp + RootView + MainTabs
  Models/          Problem, Step, MistakeTag, Unit, StudyLog, …
  Data/            *.json content (units, problems, mistake tags, …)
  Services/        DataService, ProgressStore, RouteEngine, AdSlot
  Theme/           TKColor, TKType, TKSpacing
  Components/      Reusable cards, buttons, equation views
  Views/           One folder per feature screen
  ViewModels/      Per-screen observable state
  Assets.xcassets/ App icon + accent color
```

## Features

1. Onboarding (time + lifestyle → daily recommendation)
2. Route diagnosis test (5 problems, no shaming score)
3. Home with 「つづきから」 + 今日のルート診断 + 今週カレンダー (✓ ○ ◎ -)
4. Unit selection — three units active, others 準備中
5. **Unit detail with difficulty progression** — Lv.1 → Lv.5 ladder,
   problems unlock as the user clears each level
6. Problem screen — 「次の一手」 mode
7. 式が動く解説 (animated step-by-step equation)
8. Mistake tag detection → ここだけ特訓 recovery route
9. Review box (ふくしゅう箱)
10. Study log + month calendar habit grid
11. Handwritten memo sheet (PencilKit)
12. Mini calculator
13. Settings + remove-ads placeholder

Ad slots are wired into non-learning screens only — never inside the
problem flow.

## Difficulty progression

- Each `Problem` carries `difficulty: 1...5`.
- `ProgressStore.solvedProblemIds` records what the user has cleared.
- `RouteEngine.continueTarget()` returns the **lowest-difficulty
  uncleared problem** in the current unit, falling back to the
  diagnosis-recommended set.
- `RouteEngine.isUnlocked(_:)` gates Lv.N behind clearing at least one
  Lv.N-1 problem in the same unit — a gentle, never-frustrating gate.
- `UnitDetailView` shows the ladder visually with ✓ / 🔒 markers.

## Build

Open `mathprocess.xcodeproj` in Xcode 16+ and run on an iOS 17+
simulator. The project uses Xcode 16's `PBXFileSystemSynchronizedRootGroup`,
so any new file dropped into `mathprocess/` is automatically included
in the build — no manual project editing needed.

## File map

| Concern              | Path                                       |
|----------------------|--------------------------------------------|
| App entry            | `mathprocess/App/TokeRootApp.swift`        |
| Root navigation      | `mathprocess/App/RootView.swift`           |
| Tab shell            | `mathprocess/App/MainTabs.swift`           |
| Domain models        | `mathprocess/Models/*.swift`               |
| JSON content         | `mathprocess/Data/*.json`                  |
| Data loader          | `mathprocess/Services/DataService.swift`   |
| Persisted state      | `mathprocess/Services/ProgressStore.swift` |
| Rule-based engine    | `mathprocess/Services/RouteEngine.swift`   |
| Ad slot placeholder  | `mathprocess/Services/AdSlot.swift`        |
| Theme                | `mathprocess/Theme/*.swift`                |
| Reusable UI          | `mathprocess/Components/*.swift`           |
| Onboarding           | `mathprocess/Views/Onboarding/`            |
| Diagnosis test       | `mathprocess/Views/Diagnosis/`             |
| Home                 | `mathprocess/Views/Home/`                  |
| Unit list / detail   | `mathprocess/Views/Unit/`                  |
| Problem solving      | `mathprocess/Views/Problem/` + `mathprocess/ViewModels/ProblemViewModel.swift` |
| 特訓 / recovery       | `mathprocess/Views/Recovery/`              |
| Review box           | `mathprocess/Views/Review/`                |
| Log + calendar       | `mathprocess/Views/Log/`, `mathprocess/Views/Calendar/` |
| Memo (PencilKit)     | `mathprocess/Views/Memo/`                  |
| Calculator           | `mathprocess/Views/Calculator/`            |
| Settings             | `mathprocess/Views/Settings/`              |
