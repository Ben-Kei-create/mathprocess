import SwiftUI

@main
struct TokeRootApp: App {
    @State private var data = DataService.shared
    @State private var store = ProgressStore.shared
    @State private var purchase = PurchaseService.shared
    @State private var notifications = NotificationService.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(data)
                .environment(store)
                .environment(purchase)
                .environment(notifications)
                .preferredColorScheme(.light)
                .tint(TKColor.accent)
                .task {
                    await purchase.loadProducts()
                    if await purchase.refreshEntitlements() {
                        store.profile.adsRemoved = true
                        store.save()
                    }
                    await notifications.refreshAuthorizationStatus()
                }
        }
    }
}
