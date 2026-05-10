# 解け√ルート (Toke Root)

Japanese middle-school math learning app — MVP prototype.

> 「解けないを、解けるルートに変える。」

## Concept

A calm, focused math recovery app for Japanese junior-high students.
Not a quiz app, not a camera-solver, not an AI tutor — a step-by-step
**route back to "I know what to do next."**

## MVP Scope

This prototype now includes small, carefully ordered **中1** starter units:
正負の数, 文字式, 一次方程式, 比例・反比例, and 図形. The route diagnosis still focuses on
一次方程式, but the unit list and data model are designed so future units
(一次関数, 二次方程式, 三平方の定理, …) plug in without redesign.

All problems, hints, mistake tags, recovery sets and step-by-step
explanations are **local structured data** (JSON + Swift models). No
generative AI in the MVP.

## Stack

- SwiftUI (iOS 17+)
- Swift 5.9
- `@Observable` view models
- `UserDefaults` + JSON-encoded snapshot for persistence
- No third-party dependencies

## Project layout

```
TokeRoot/
  App/             App entry point + root navigation
  Models/          Domain types: Problem, Step, MistakeTag, Unit, …
  Data/            Local JSON: units.json, problems_*.json
  Services/        DataService, ProgressStore, RouteEngine
  Theme/           TKColor, TKType, TKSpacing
  Components/      Reusable cards, buttons, equation views
  Views/           One folder per feature screen
  ViewModels/      Per-screen observable state
```

## Features (MVP)

1. Onboarding (time + lifestyle → daily recommendation)
2. Route diagnosis test (5 problems)
3. Home with 「つづきから」
4. Unit selection (一次方程式 active, others 準備中)
5. Problem screen — 「次の一手」 mode
6. 式が動く解説 (animated step-by-step equation)
7. Inline handwritten scratch memo while solving
8. Handwritten final-answer box for 自力モード, checked locally first
9. Spaced review scheduling (1, 3, 7, 14, 30 days)
10. Mistake tag detection + recovery route
11. ここだけ特訓 mini-set
12. Review box
13. Study log + weekly calendar (✓ ○ ◎ -)
14. Memo sheet
15. Mini calculator
16. Settings + remove-ads placeholder

The handwritten answer flow uses on-device recognition first so routine checks
cost nothing. A future API fallback can be added only for the small final-answer
crop, while scratch memo pages stay local.

Ad slots are wired into non-learning screens only — never inside the
problem flow.

## Build

The Xcode project is generated from `project.yml` via
[XcodeGen](https://github.com/yonaskolb/XcodeGen).

```sh
brew install xcodegen
xcodegen generate
open TokeRoot.xcodeproj
```

Then run on an iOS 17 simulator (iPhone 15 recommended). No third-party
dependencies — first build is fast.

## File map

| Concern              | Path                               |
|----------------------|------------------------------------|
| App entry            | `TokeRoot/App/TokeRootApp.swift`   |
| Root navigation      | `TokeRoot/App/RootView.swift`      |
| Tab shell            | `TokeRoot/App/MainTabs.swift`      |
| Domain models        | `TokeRoot/Models/*.swift`          |
| JSON content         | `TokeRoot/Data/*.json`             |
| Data loader          | `TokeRoot/Services/DataService.swift` |
| Persisted state      | `TokeRoot/Services/ProgressStore.swift` |
| Rule-based engine    | `TokeRoot/Services/RouteEngine.swift` |
| Ad slot placeholder  | `TokeRoot/Services/AdSlot.swift`   |
| Theme                | `TokeRoot/Theme/*.swift`           |
| Reusable UI          | `TokeRoot/Components/*.swift`      |
| Onboarding           | `TokeRoot/Views/Onboarding/`       |
| Diagnosis test       | `TokeRoot/Views/Diagnosis/`        |
| Home                 | `TokeRoot/Views/Home/`             |
| Unit selection       | `TokeRoot/Views/Unit/`             |
| Problem solving      | `TokeRoot/Views/Problem/` + `ViewModels/ProblemViewModel.swift` |
| 特訓 / recovery       | `TokeRoot/Views/Recovery/`         |
| Review box           | `TokeRoot/Views/Review/`           |
| Log + calendar       | `TokeRoot/Views/Log/`, `TokeRoot/Views/Calendar/` |
| Memo                 | `TokeRoot/Views/Memo/`             |
| Calculator           | `TokeRoot/Views/Calculator/`       |
| Settings             | `TokeRoot/Views/Settings/`         |
