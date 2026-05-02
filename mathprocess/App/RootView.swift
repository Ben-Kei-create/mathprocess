import SwiftUI

/// Owns top-level routing:
///  - first launch    -> Onboarding
///  - onboarding done -> Diagnosis test (one-time per unit)
///  - everything else -> MainTabs (Home / Log / Review / Settings)
struct RootView: View {
    @Environment(ProgressStore.self) private var store

    var body: some View {
        Group {
            if !store.profile.hasCompletedOnboarding {
                OnboardingFlow()
                    .transition(.opacity)
            } else if !store.profile.hasCompletedDiagnosis {
                DiagnosisFlow(unitId: "g1-linear-eq")
                    .transition(.opacity)
            } else {
                MainTabs()
                    .transition(.opacity)
            }
        }
        .background(TKColor.background.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.25), value: store.profile.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.25), value: store.profile.hasCompletedDiagnosis)
    }
}
