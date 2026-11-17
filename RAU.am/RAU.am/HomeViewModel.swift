import Foundation
import NetworkLayer

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var news: Loadable<[Post]> = .idle
    @Published private(set) var anons: Loadable<[Post]> = .idle
    @Published private(set) var institutes: Loadable<[Institute]> = .idle
    @Published private(set) var statistics: Loadable<[Statistic]> = .idle
    @Published private(set) var courses: Loadable<TitledList<Course>> = .idle
    @Published private(set) var categories: Loadable<TitledList<SiteCategory>> = .idle

    /// Loads the three home sections in parallel; each one succeeds or fails on its own.
    func load(api: API) async {
        if news.value == nil { news = .loading }
        if anons.value == nil { anons = .loading }
        if institutes.value == nil { institutes = .loading }
        if statistics.value == nil { statistics = .loading }
        if courses.value == nil { courses = .loading }
        if categories.value == nil { categories = .loading }

        async let newsResult = Loadable.capture { try await api.news.list(page: 1, perPage: 6).items }
        async let anonsResult = Loadable.capture { try await api.announcements.list(page: 1, perPage: 4).items }
        async let institutesResult = Loadable.capture { try await api.institutes.list() }
        async let statisticsResult = Loadable.capture { try await api.statistics.list() }
        async let coursesResult = Loadable.capture { try await api.courses.list() }
        async let categoriesResult = Loadable.capture { try await api.categories.list() }
        let (n, a, i) = await (newsResult, anonsResult, institutesResult)
        let (s, co, ca) = await (statisticsResult, coursesResult, categoriesResult)

        if case .idle = n {} else { news = n }
        if case .idle = a {} else { anons = a }
        if case .idle = i {} else { institutes = i }
        if case .idle = s {} else { statistics = s }
        if case .idle = co {} else { courses = co }
        if case .idle = ca {} else { categories = ca }
    }
}
