import SwiftUI

struct MainTabs: View {
    @State private var selection: Tab = .home

    enum Tab: Hashable { case home, study, log, review, settings }

    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem { Label("ホーム",   systemImage: "house") }
                .tag(Tab.home)

            StudyGuideView()
                .tabItem { Label("勉強",     systemImage: "book.closed") }
                .tag(Tab.study)

            LogView()
                .tabItem { Label("記録",     systemImage: "calendar") }
                .tag(Tab.log)

            ReviewBoxView()
                .tabItem { Label("ふくしゅう", systemImage: "tray.full") }
                .tag(Tab.review)

            SettingsView()
                .tabItem { Label("設定",     systemImage: "gearshape") }
                .tag(Tab.settings)
        }
    }
}
