import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var app: AppModel

    var body: some View {
        TabView(selection: $app.selectedTab) {
            HomeView()
                .tabItem { Label(L10n.home.text(app.language), systemImage: "house.fill") }
                .tag(AppTab.home)
            PostListView(kind: .news)
                .tabItem { Label(L10n.news.text(app.language), systemImage: "newspaper.fill") }
                .tag(AppTab.news)
            PostListView(kind: .anons)
                .tabItem { Label(L10n.announcements.text(app.language), systemImage: "megaphone.fill") }
                .tag(AppTab.anons)
            InstitutesView()
                .tabItem { Label(L10n.institutes.text(app.language), systemImage: "building.columns.fill") }
                .tag(AppTab.institutes)
            MenuView()
                .tabItem { Label(L10n.menu.text(app.language), systemImage: "line.3.horizontal") }
                .tag(AppTab.menu)
        }
        .tint(Theme.crimson)
    }
}
