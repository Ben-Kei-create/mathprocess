import SwiftUI

@main
struct TokeRootApp: App {
    @State private var data = DataService.shared
    @State private var store = ProgressStore.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(data)
                .environment(store)
                .preferredColorScheme(.light)
                .tint(TKColor.accent)
        }
    }
}
