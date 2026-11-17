import Foundation

extension APIClientProtocol {
    /// Requests an endpoint answering with the `{data, success, lang}` envelope and returns `data`.
    func requestData<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T {
        let response = try await request(endpoint, as: APIResponse<T>.self)
        guard response.success else { throw NetworkError.unsuccessfulResponse }
        return response.data
    }

    /// For lists that carry a section title (courses, categories).
    func requestTitled<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> TitledList<T> {
        let response = try await request(endpoint, as: APIResponse<[T]>.self)
        guard response.success else { throw NetworkError.unsuccessfulResponse }
        return TitledList(title: response.title, items: response.data)
    }

    /// Same, for list endpoints: keeps the `meta` paging block.
    func requestPaginated<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> Paginated<T> {
        let response = try await request(endpoint, as: APIResponse<[T]>.self)
        guard response.success else { throw NetworkError.unsuccessfulResponse }
        return Paginated(items: response.data, meta: response.meta)
    }
}

// MARK: - Institutes
public protocol InstitutesServiceProtocol: Sendable {
    func list() async throws -> [Institute]
    func detail(slug: String) async throws -> InstituteDetail
}

public struct InstitutesService: InstitutesServiceProtocol {
    private let client: APIClientProtocol
    public init(client: APIClientProtocol) { self.client = client }

    public func list() async throws -> [Institute] {
        try await client.requestData(.institutes(), as: [Institute].self)
    }
    public func detail(slug: String) async throws -> InstituteDetail {
        try await client.requestData(.institute(slug: slug), as: InstituteDetail.self)
    }
}

// MARK: - News
public protocol NewsServiceProtocol: Sendable {
    func list(page: Int, perPage: Int) async throws -> Paginated<News>
    func detail(permalink: String) async throws -> NewsDetail
}

public struct NewsService: NewsServiceProtocol {
    private let client: APIClientProtocol
    public init(client: APIClientProtocol) { self.client = client }

    public func list(page: Int, perPage: Int) async throws -> Paginated<News> {
        try await client.requestPaginated(.news(page: page, perPage: perPage), as: News.self)
    }
    public func detail(permalink: String) async throws -> NewsDetail {
        try await client.requestData(.newsItem(permalink: permalink), as: NewsDetail.self)
    }
}

// MARK: - Announcements ("anons")
public protocol AnnouncementsServiceProtocol: Sendable {
    func list(page: Int, perPage: Int) async throws -> Paginated<Announcement>
    func detail(permalink: String) async throws -> AnnouncementDetail
}

public struct AnnouncementsService: AnnouncementsServiceProtocol {
    private let client: APIClientProtocol
    public init(client: APIClientProtocol) { self.client = client }

    public func list(page: Int, perPage: Int) async throws -> Paginated<Announcement> {
        try await client.requestPaginated(.announcements(page: page, perPage: perPage), as: Announcement.self)
    }
    public func detail(permalink: String) async throws -> AnnouncementDetail {
        try await client.requestData(.announcement(permalink: permalink), as: AnnouncementDetail.self)
    }
}

// MARK: - Pages
public protocol PagesServiceProtocol: Sendable {
    func list(page: Int, perPage: Int) async throws -> Paginated<Page>
    func detail(permalink: String) async throws -> PageDetail
}

public struct PagesService: PagesServiceProtocol {
    private let client: APIClientProtocol
    public init(client: APIClientProtocol) { self.client = client }

    public func list(page: Int, perPage: Int) async throws -> Paginated<Page> {
        try await client.requestPaginated(.pages(page: page, perPage: perPage), as: Page.self)
    }
    public func detail(permalink: String) async throws -> PageDetail {
        try await client.requestData(.page(permalink: permalink), as: PageDetail.self)
    }
}

// MARK: - Menus (a tree, not paginated)
public protocol MenusServiceProtocol: Sendable {
    func list() async throws -> [MenuItem]
}

public struct MenusService: MenusServiceProtocol {
    private let client: APIClientProtocol
    public init(client: APIClientProtocol) { self.client = client }

    public func list() async throws -> [MenuItem] {
        try await client.requestData(.menus(), as: [MenuItem].self)
    }
}

// MARK: - Statistics / Courses / Categories (not paginated)
public protocol StatisticsServiceProtocol: Sendable {
    func list() async throws -> [Statistic]
}
public struct StatisticsService: StatisticsServiceProtocol {
    private let client: APIClientProtocol
    public init(client: APIClientProtocol) { self.client = client }
    public func list() async throws -> [Statistic] {
        try await client.requestData(.statistics(), as: [Statistic].self)
    }
}

public protocol CoursesServiceProtocol: Sendable {
    func list() async throws -> TitledList<Course>
}
public struct CoursesService: CoursesServiceProtocol {
    private let client: APIClientProtocol
    public init(client: APIClientProtocol) { self.client = client }
    public func list() async throws -> TitledList<Course> {
        try await client.requestTitled(.courses(), as: Course.self)
    }
}

public protocol CategoriesServiceProtocol: Sendable {
    func list() async throws -> TitledList<SiteCategory>
}
public struct CategoriesService: CategoriesServiceProtocol {
    private let client: APIClientProtocol
    public init(client: APIClientProtocol) { self.client = client }
    public func list() async throws -> TitledList<SiteCategory> {
        try await client.requestTitled(.categories(), as: SiteCategory.self)
    }
}

// MARK: - Default paging so callers can simply write `try await api.news.list()`
public extension NewsServiceProtocol {
    func list() async throws -> Paginated<News> { try await list(page: 1, perPage: 10) }
}
public extension AnnouncementsServiceProtocol {
    func list() async throws -> Paginated<Announcement> { try await list(page: 1, perPage: 10) }
}
public extension PagesServiceProtocol {
    func list() async throws -> Paginated<Page> { try await list(page: 1, perPage: 10) }
}
