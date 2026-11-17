import SwiftUI
import NetworkLayer

struct HomeView: View {
    @EnvironmentObject private var app: AppModel
    @StateObject private var model = HomeViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    heroSection
                    newsSection
                    anonsSection
                    StatsSection(state: model.statistics)
                    CoursesSection(state: model.courses)
                    QuickLinksSection(state: model.categories)
                    institutesSection
                    FooterSection()
                }
            }
            .refreshable { await model.load(api: app.api) }
            .task(id: app.generation) { await model.load(api: app.api) }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 6) {
                        Image(systemName: "graduationcap.fill").foregroundColor(Theme.crimson)
                        Text("RAU").font(.headline.weight(.heavy)).foregroundColor(Theme.navy)
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if let phone = URL(string: "tel:+37412775775") {
                        Link(destination: phone) { Image(systemName: "phone.fill") }
                    }
                    LanguageMenu()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: Sections

    @ViewBuilder private var heroSection: some View {
        switch model.news {
        case .loaded(let posts):
            HeroSlider(posts: Array(posts.prefix(3)))
        case .failed(let message):
            ErrorBanner(message: message) { Task { await model.load(api: app.api) } }
        default:
            Color(.secondarySystemBackground).frame(height: 300).overlay(ProgressView())
        }
    }

    @ViewBuilder private var newsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: L10n.news.text(app.language),
                          actionTitle: L10n.viewAll.text(app.language)) { app.selectedTab = .news }
            if case .loaded(let posts) = model.news {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 14) {
                        ForEach(posts) { post in
                            PostLink(post: post) { PostCard(post: post) }
                                .buttonStyle(.plain)
                                .frame(width: 280)
                        }
                    }
                    .padding(.horizontal)
                }
            } else if case .loading = model.news {
                LoadingBlock()
            }
        }
    }

    @ViewBuilder private var anonsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: L10n.announcements.text(app.language),
                          actionTitle: L10n.viewAll.text(app.language)) { app.selectedTab = .anons }
            switch model.anons {
            case .loaded(let posts):
                VStack(spacing: 14) {
                    ForEach(posts) { post in
                        PostLink(post: post) { PostRow(post: post, showsDate: false) }
                            .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            case .failed(let message):
                ErrorBanner(message: message) { Task { await model.load(api: app.api) } }
            default:
                LoadingBlock()
            }
        }
    }

    @ViewBuilder private var institutesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: L10n.institutes.text(app.language),
                          actionTitle: L10n.viewAll.text(app.language)) { app.selectedTab = .institutes }
            if case .loaded(let institutes) = model.institutes {
                VStack(spacing: 0) {
                    ForEach(Array(institutes.prefix(5).enumerated()), id: \.element.id) { index, institute in
                        InstituteRow(institute: institute)
                        if index < min(institutes.count, 5) - 1 { Divider() }
                    }
                }
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            } else if case .loading = model.institutes {
                LoadingBlock()
            }
        }
    }
}

// MARK: - Hero slider (the website's top banner)

struct HeroSlider: View {
    @EnvironmentObject private var app: AppModel
    let posts: [Post]

    @State private var index = 0
    private let timer = Timer.publish(every: 6, on: .main, in: .common).autoconnect()

    var body: some View {
        TabView(selection: $index) {
            ForEach(Array(posts.enumerated()), id: \.element.id) { offset, post in
                PostLink(post: post) { slide(post) }
                    .buttonStyle(.plain)
                    .tag(offset)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .frame(height: 320)
        .onReceive(timer) { _ in
            guard posts.count > 1 else { return }
            withAnimation { index = (index + 1) % posts.count }
        }
    }

    private func slide(_ post: Post) -> some View {
        ZStack(alignment: .bottomLeading) {
            CoverImage(url: post.banner ?? post.image, height: 320)
            Theme.heroOverlay
            VStack(alignment: .leading, spacing: 8) {
                Text(post.title)
                    .font(.title3.bold())
                    .foregroundColor(.white)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                if let subtitle = post.subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Text(L10n.details.text(app.language))
                    .font(.footnote.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14).padding(.vertical, 7)
                    .background(Theme.crimson)
                    .clipShape(Capsule())
            }
            .padding(.horizontal)
            .padding(.bottom, 36)
        }
        .frame(height: 320)
        .clipped()
    }
}

// MARK: - Institutes row

struct InstituteRow: View {
    let institute: Institute

    var body: some View {
        WebLinkButton(url: institute.url) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(institute.name).font(.subheadline.weight(.semibold)).multilineTextAlignment(.leading)
                    if let host = institute.url?.host {
                        Text(host).font(.caption).foregroundColor(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "arrow.up.right").font(.footnote).foregroundColor(Theme.crimson)
            }
            .padding(14)
            .contentShape(Rectangle())
        }
    }
}

// MARK: - Statistics (GET /statistics)

struct StatsSection: View {
    let state: Loadable<[Statistic]>

    var body: some View {
        if case .loaded(let items) = state, !items.isEmpty {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                ForEach(items) { item in
                    VStack(spacing: 4) {
                        Text(item.count.formatted(.number.grouping(.never)))
                            .font(.system(size: 32, weight: .heavy))
                            .foregroundColor(.white)
                        Text(item.title)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, minHeight: 90)
                    .padding(.horizontal, 8)
                }
            }
            .padding()
            .background(Theme.navy)
        }
    }
}

// MARK: - Courses and sections (GET /courses)

struct CoursesSection: View {
    let state: Loadable<TitledList<Course>>

    var body: some View {
        if case .loaded(let list) = state, !list.items.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                if let title = list.title { SectionHeader(title: title) }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 14) {
                        ForEach(list.items.sorted { $0.order < $1.order }) { course in
                            WebLinkButton(url: course.url ?? course.link) {
                                VStack(alignment: .leading, spacing: 8) {
                                    CoverImage(url: course.image, aspect: 16.0 / 10.0)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    Text(course.name)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(2)
                                    if let subtitle = course.subtitle {
                                        Text(subtitle).font(.footnote).foregroundColor(.secondary).lineLimit(2)
                                    }
                                }
                                .frame(width: 200, alignment: .leading)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - Categories / quick links (GET /categories)

struct QuickLinksSection: View {
    let state: Loadable<TitledList<SiteCategory>>

    var body: some View {
        if case .loaded(let list) = state, !list.items.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                if let title = list.title { SectionHeader(title: title) }
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(list.items.sorted { $0.order < $1.order }) { category in
                        WebLinkButton(url: category.url ?? category.link) {
                            HStack(spacing: 10) {
                                CoverImage(url: category.icon, aspect: 1)
                                    .frame(width: 36)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                Text(category.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                                Spacer(minLength: 0)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Footer

struct FooterSection: View {
    @EnvironmentObject private var app: AppModel

    private let social: [(name: String, url: String)] = [
        ("Facebook", "https://www.facebook.com/RAUOfficial/"),
        ("Instagram", "https://www.instagram.com/universityrau/"),
        ("YouTube", "https://www.youtube.com/channel/UC2qRc3Wt_9D58CURNb7PtgA"),
        ("LinkedIn", "https://www.linkedin.com/school/russian---armenian-university/"),
        ("Telegram", "https://t.me/RAU_uni"),
        ("X", "https://twitter.com/RAU_uni"),
        ("VK", "https://vk.com/rau_uni"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "graduationcap.fill").foregroundColor(.white)
                Text("Russian-Armenian University").font(.headline).foregroundColor(.white)
            }

            Text(L10n.contacts.text(app.language)).font(.subheadline.weight(.bold)).foregroundColor(.white.opacity(0.7))
            if let call = URL(string: "tel:+37412775775") {
                Link("(+374 12) 775 775", destination: call).foregroundColor(.white)
            }
            Text("\(L10n.admissionsInfo.text(app.language)): (+374 91) 933 123, (+374 99) 406 157")
                .font(.footnote)
                .foregroundColor(.white.opacity(0.8))

            Text(L10n.followUs.text(app.language)).font(.subheadline.weight(.bold)).foregroundColor(.white.opacity(0.7))
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(social, id: \.name) { item in
                    WebLinkButton(url: URL(string: item.url)) {
                        Text(item.name)
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
            }

            Text("© rau.am 2005 – 2026")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .padding(.top, 6)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.navy)
    }
}
