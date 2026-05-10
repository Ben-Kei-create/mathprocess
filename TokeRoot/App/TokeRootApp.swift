import SwiftUI

@main
struct TokeRootApp: App {
    @State private var data = DataService.shared
    @State private var store = ProgressStore.shared
    @State private var notifications = NotificationService.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(data)
                .environment(store)
                .environment(notifications)
                .preferredColorScheme(.light)
                .tint(TKColor.accent)
                .task {
                    await notifications.refreshAuthorizationStatus()
                }
        }
    }
}
