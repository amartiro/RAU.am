import SwiftUI
import NetworkLayer

// MARK: - News / Anons (paginated lists)

struct PostListView: View {
    enum Kind { case news, anons }

    @EnvironmentObject private var app: AppModel
    @StateObject private var model: PagedListViewModel<Post>
    private let kind: Kind

    init(kind: Kind) {
        self.kind = kind
        _model = StateObject(wrappedValue: PagedListViewModel<Post>(perPage: kind == .news ? 10 : 20) { api, page, perPage in
            switch kind {
            case .news: return try await api.news.list(page: page, perPage: perPage)
            case .anons: return try await api.announcements.list(page: page, perPage: perPage)
            }
        })
    }

    private var title: String {
        (kind == .news ? L10n.news : L10n.announcements).text(app.language)
    }

    var body: some View {
        NavigationStack {
            Group {
                if model.items.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle(title)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { LanguageMenu() } }
            .task(id: app.generation) { await model.reload(api: app.api) }
        }
    }

    private var list: some View {
        List {
            ForEach(model.items) { post in
                PostLink(post: post) { PostRow(post: post, showsDate: kind == .news) }
                    .task { await model.loadMoreIfNeeded(current: post, api: app.api) }
            }
            if model.isLoading {
                HStack { Spacer(); ProgressView(); Spacer() }.listRowSeparator(.hidden)
            }
            if let message = model.errorMessage {
                ErrorBanner(message: message) { Task { await model.loadMore(api: app.api) } }
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .refreshable { await model.reload(api: app.api) }
    }

    @ViewBuilder private var emptyState: some View {
        if let message = model.errorMessage {
            ErrorBanner(message: message) { Task { await model.reload(api: app.api) } }
        } else if model.isLoading {
            ProgressView(L10n.loading.text(app.language))
        } else {
            Text(L10n.noData.text(app.language)).foregroundColor(.secondary)
        }
    }
}

// MARK: - Institutes

struct InstitutesView: View {
    @EnvironmentObject private var app: AppModel
    @State private var state: Loadable<[Institute]> = .idle

    var body: some View {
        NavigationStack {
            Group {
                switch state {
                case .loaded(let institutes):
                    List(institutes) { institute in
                        InstituteRow(institute: institute)
                            .listRowInsets(EdgeInsets())
                    }
                    .listStyle(.plain)
                    .refreshable { await load() }
                case .failed(let message):
                    ErrorBanner(message: message) { Task { await load() } }
                default:
                    ProgressView(L10n.loading.text(app.language))
                }
            }
            .navigationTitle(L10n.institutes.text(app.language))
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { LanguageMenu() } }
            .task(id: app.generation) { await load() }
        }
    }

    private func load() async {
        if state.value == nil { state = .loading }
        let result = await Loadable.capture { try await app.api.institutes.list() }
        if case .idle = result { return }
        state = result
    }
}

// MARK: - Menu + Pages

struct MenuView: View {
    @EnvironmentObject private var app: AppModel
    @State private var state: Loadable<[MenuItem]> = .idle

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        PagesListView()
                    } label: {
                        Label(L10n.pages.text(app.language), systemImage: "doc.text")
                    }
                }

                Section(header: Text(L10n.language.text(app.language))) {
                    Picker(selection: $app.language) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.nativeName).tag(language)
                        }
                    } label: {
                        Label(L10n.language.text(app.language), systemImage: "globe")
                    }
                    .pickerStyle(.segmented)
                }

                switch state {
                case .loaded(let items):
                    ForEach(items) { top in
                        Section(header: Text(top.name)) { rows(for: top) }
                    }
                case .failed(let message):
                    ErrorBanner(message: message) { Task { await load() } }
                default:
                    HStack { Spacer(); ProgressView(); Spacer() }
                }
            }
            .listStyle(.insetGrouped)
            .refreshable { await load() }
            .navigationTitle(L10n.menu.text(app.language))
            .task(id: app.generation) { await load() }
        }
    }

    @ViewBuilder private func rows(for item: MenuItem) -> some View {
        if item.children.isEmpty {
            linkRow(item)
        } else {
            ForEach(item.children) { child in linkRow(child) }
        }
    }

    @ViewBuilder private func linkRow(_ item: MenuItem) -> some View {
        if let url = item.url ?? item.link {
            WebLinkButton(url: url) {
                HStack {
                    Text(item.name).multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: "arrow.up.right").font(.footnote).foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
            }
        } else {
            Text(item.name).foregroundColor(.secondary)
        }
    }

    private func load() async {
        if state.value == nil { state = .loading }
        let result = await Loadable.capture { try await app.api.menus.list() }
        if case .idle = result { return }
        state = result
    }
}

struct PagesListView: View {
    @EnvironmentObject private var app: AppModel
    @StateObject private var model = PagedListViewModel<Page>(perPage: 10) { api, page, perPage in
        try await api.pages.list(page: page, perPage: perPage)
    }

    var body: some View {
        Group {
            if model.items.isEmpty {
                if let message = model.errorMessage {
                    ErrorBanner(message: message) { Task { await model.reload(api: app.api) } }
                } else if model.isLoading {
                    ProgressView(L10n.loading.text(app.language))
                } else {
                    Text(L10n.noData.text(app.language)).foregroundColor(.secondary)
                }
            } else {
                List {
                    ForEach(model.items) { page in
                        WebLinkButton(url: page.url) { PageRow(page: page) }
                            .task { await model.loadMoreIfNeeded(current: page, api: app.api) }
                    }
                    if model.isLoading {
                        HStack { Spacer(); ProgressView(); Spacer() }
                    }
                }
                .listStyle(.plain)
                .refreshable { await model.reload(api: app.api) }
            }
        }
        .navigationTitle(L10n.pages.text(app.language))
        .task(id: app.generation) { await model.reload(api: app.api) }
    }
}

private struct PageRow: View {
    let page: Page

    var body: some View {
        HStack(spacing: 12) {
            CoverImage(url: page.banner, aspect: 4.0 / 3.0)
                .frame(width: 90)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 4) {
                Text(page.title)
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                if let text = page.shortDescription {
                    Text(text).font(.footnote).foregroundColor(.secondary).lineLimit(2)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}
