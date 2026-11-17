import Foundation

/// Single entry point for the app:
///
///     let api = API(baseURL: URL(string: "https://example.com/api/v1")!)
///     let news = try await api.news.list().items
public struct API: Sendable {
    public let institutes: InstitutesServiceProtocol
    public let news: NewsServiceProtocol
    public let announcements: AnnouncementsServiceProtocol
    public let pages: PagesServiceProtocol
    public let menus: MenusServiceProtocol
    public let statistics: StatisticsServiceProtocol
    public let courses: CoursesServiceProtocol
    public let categories: CategoriesServiceProtocol

    public init(client: APIClientProtocol) {
        self.institutes = InstitutesService(client: client)
        self.news = NewsService(client: client)
        self.announcements = AnnouncementsService(client: client)
        self.pages = PagesService(client: client)
        self.menus = MenusService(client: client)
        self.statistics = StatisticsService(client: client)
        self.courses = CoursesService(client: client)
        self.categories = CategoriesService(client: client)
    }

    /// - Parameter queryItems: sent with every request, e.g. `[URLQueryItem(name: "lang", value: "2")]`.
    public init(baseURL: URL,
                session: URLSession = .shared,
                headers: [String: String] = ["Accept": "application/json"],
                queryItems: [URLQueryItem] = []) {
        self.init(client: APIClient(baseURL: baseURL,
                                    http: URLSessionHTTPClient(session: session),
                                    defaultHeaders: headers,
                                    defaultQueryItems: queryItems))
    }
}
