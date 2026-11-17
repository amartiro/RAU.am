import XCTest
import TestSupport
@testable import NetworkLayer

/// Services are tested against a mocked `APIClientProtocol`: we only verify routing + result forwarding.
final class ServicesTests: XCTestCase {
    private let meta = PageMeta(page: 1, perPage: 10, total: 351, lastPage: 36, hasMore: true)

    // MARK: Institutes
    func test_institutes_list_requestsCorrectEndpoint() async throws {
        let items = try decode([Institute].self, Fixtures.institutesList)
        let client = MockAPIClient { _ in APIResponse(data: items) }

        let result = try await InstitutesService(client: client).list()

        XCTAssertEqual(result, items)
        XCTAssertEqual(client.endpoints, [.institutes()])
        XCTAssertTrue(client.endpoints[0].queryItems.isEmpty)      // not paginated
    }

    func test_institutes_detail() async throws {
        let expected = try decode(InstituteDetail.self, Fixtures.instituteDetail)
        let client = MockAPIClient { _ in APIResponse(data: expected) }

        let result = try await InstitutesService(client: client).detail(slug: "sociopolitics")

        XCTAssertEqual(result, expected)
        XCTAssertEqual(client.endpoints, [.institute(slug: "sociopolitics")])
    }

    // MARK: News
    func test_news_list_keepsPagingMeta_andDetail() async throws {
        let list = try decode([News].self, Fixtures.newsList)
        let detail = try decode(NewsDetail.self, Fixtures.newsDetail)
        let meta = self.meta
        let client = MockAPIClient { endpoint in
            if endpoint.path == "/news" { return APIResponse(data: list, meta: meta) }
            return APIResponse(data: detail)
        }
        let service = NewsService(client: client)

        let page = try await service.list(page: 1, perPage: 10)
        let fetchedDetail = try await service.detail(permalink: "rus-lit-conf26")

        XCTAssertEqual(page.items, list)
        XCTAssertEqual(page.meta, meta)
        XCTAssertTrue(page.hasMore)
        XCTAssertEqual(fetchedDetail, detail)
        XCTAssertEqual(client.endpoints, [.news(page: 1, perPage: 10), .newsItem(permalink: "rus-lit-conf26")])
    }

    // MARK: Announcements
    func test_announcements_list_andDetail() async throws {
        let list = try decode([Announcement].self, Fixtures.announcementsList)
        let detail = try decode(AnnouncementDetail.self, Fixtures.announcementDetail)
        let client = MockAPIClient { endpoint in
            if endpoint.path == "/anons" { return APIResponse(data: list) }
            return APIResponse(data: detail)
        }
        let service = AnnouncementsService(client: client)

        let page = try await service.list(page: 1, perPage: 10)
        let fetchedDetail = try await service.detail(permalink: "conference-2026")

        XCTAssertEqual(page.items, list)
        XCTAssertEqual(fetchedDetail, detail)
        XCTAssertEqual(client.endpoints, [.announcements(page: 1, perPage: 10), .announcement(permalink: "conference-2026")])
    }

    // MARK: Pages
    func test_pages_list_andDetail() async throws {
        let list = try decode([Page].self, Fixtures.pagesList)
        let detail = try decode(PageDetail.self, Fixtures.pageDetail)
        let client = MockAPIClient { endpoint in
            if endpoint.path == "/pages" { return APIResponse(data: list) }
            return APIResponse(data: detail)
        }
        let service = PagesService(client: client)

        let page = try await service.list(page: 1, perPage: 10)
        let fetchedDetail = try await service.detail(permalink: "sustainability")

        XCTAssertEqual(page.items, list)
        XCTAssertEqual(fetchedDetail, detail)
        XCTAssertEqual(client.endpoints, [.pages(page: 1, perPage: 10), .page(permalink: "sustainability")])
    }

    // MARK: Menus
    func test_menus_list() async throws {
        let menus = try decode([MenuItem].self, Fixtures.menusList)
        let client = MockAPIClient { _ in APIResponse(data: menus) }

        let result = try await MenusService(client: client).list()

        XCTAssertEqual(result, menus)
        XCTAssertEqual(client.endpoints, [.menus()])
    }

    // MARK: Facade + defaults
    func test_api_facade_defaultPaging() async throws {
        let client = MockAPIClient { _ in APIResponse(data: [Page]()) }
        let api = API(client: client)

        _ = try await api.pages.list()          // uses protocol-extension defaults

        XCTAssertEqual(client.endpoints, [.pages(page: 1, perPage: 10)])
    }

    // MARK: Error propagation
    func test_services_propagateClientErrors() async {
        let client = MockAPIClient { _ in throw NetworkError.serverError(statusCode: 500, body: Data()) }
        let api = API(client: client)

        let errors = [
            await captureError { try await api.institutes.list() },
            await captureError { try await api.news.detail(permalink: "x") },
            await captureError { try await api.announcements.list() },
            await captureError { try await api.pages.detail(permalink: "x") },
            await captureError { try await api.menus.list() },
        ]

        for error in errors {
            XCTAssertEqual(error as? NetworkError, .serverError(statusCode: 500, body: Data()))
        }
    }

    // MARK: Helpers
    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try JSONDecoder.api().decode(T.self, from: Fixtures.data(json))
    }
}
