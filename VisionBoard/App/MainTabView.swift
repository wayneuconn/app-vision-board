import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("愿景板", systemImage: selectedTab == 0 ? "sparkles.rectangle.stack.fill" : "sparkles.rectangle.stack")
                }
                .tag(0)

            JournalView()
                .tabItem {
                    Label("今日", systemImage: selectedTab == 1 ? "sun.max.fill" : "sun.max")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("设置", systemImage: selectedTab == 2 ? "gearshape.fill" : "gearshape")
                }
                .tag(2)
        }
        .tint(AppColor.primary)
    }
}
