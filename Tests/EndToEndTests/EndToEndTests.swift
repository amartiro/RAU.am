import XCTest
import TestSupport
@testable import NetworkLayer

/// End-to-end tests: NOTHING is mocked in the client.
/// A real HTTP server (`LocalHTTPServer`) listens on 127.0.0.1:<random port> and the production
/// `API` talks to it through a real `URLSession` and real TCP sockets.
final class EndToEndTests: XCTestCase {
    private var server: LocalHTTPServer!
    private var apiBaseURL: URL!
    private var api: API!

    override func setUp() async throws {
        try await super.setUp()
        server = FakeAPIServer.makeServer()
        try await server.start()
        apiBaseURL = server.baseURL.appendingPathComponent("api/v1")
        api = API(baseURL: apiBaseURL,
                  session: URLSession(configuration: .ephemeral),
                  headers: ["Accept": "application/json", "X-Api-Key": "secret"])
    }

    override func tearDown() async throws {
        server.stop()
        server = nil
        api = nil
        try await super.tearDown()
    }

    // MARK: Models over real HTTP

    func test_institutes() async throws {
        let institutes = try await api.institutes.list()
        XCTAssertEqual(institutes.map(\.slug), ["sociopolitics", "imi"])
        XCTAssertEqual(institutes.first?.url, URL(string: "https://sociopolitics.rau.am"))

        let detail = try await api.institutes.detail(slug: "sociopolitics")
        XCTAssertEqual(detail.departments.map(\.name), ["Political Science", "History"])

        let minimal = try await api.institutes.detail(slug: "imi")
        XCTAssertTrue(minimal.departments.isEmpty)
    }

    func test_news() async throws {
        let page = try await api.news.list()
        XCTAssertEqual(page.items.map(\.id), [4533, 4530])
        XCTAssertEqual(page.meta, PageMeta(page: 1, perPage: 10, total: 351, lastPage: 36, hasMore: true))

        let detail = try await api.news.detail(permalink: "rus-lit-conf26")
        XCTAssertEqual(detail.gallery.count, 2)
        XCTAssertEqual(detail.date, Fixtures.date("2026-10-15T08:42:28Z"))
    }

    func test_announcements() async throws {
        let page = try await api.announcements.list()
        XCTAssertEqual(page.items.map(\.group), ["anons", "anons"])
        XCTAssertFalse(page.hasMore)

        let detail = try await api.announcements.detail(permalink: "conference-2026")
        XCTAssertEqual(detail.id, 4367)
    }

    func test_pages() async throws {
        let page = try await api.pages.list()
        XCTAssertEqual(page.items.map(\.slug), ["sustainability", "international"])
        XCTAssertNotNil(page.items[0].banner)

        let detail = try await api.pages.detail(permalink: "sustainability")
        XCTAssertEqual(detail.description, "<p>Our sustainability goals.</p>")
    }

    func test_menus() async throws {
        let menus = try await api.menus.list()
        XCTAssertEqual(menus.map(\.id), [28, 30])
        XCTAssertEqual(menus[0].children.map(\.name).first, "RAU Rector")
    }

    func test_statisticsCoursesCategories() async throws {
        let statistics = try await api.statistics.list()
        XCTAssertEqual(statistics.first, Statistic(count: 8, title: "Институтов"))

        let courses = try await api.courses.list()
        XCTAssertEqual(courses.title, "Курсы и Разделы")
        XCTAssertEqual(courses.items.last?.subtitle, "Digital")

        let categories = try await api.categories.list()
        XCTAssertEqual(categories.items.map(\.name), ["Международный отдел", "РАУ ТВ"])
    }

    // MARK: What the server actually received

    func test_serverReceivesPathQueryAndHeaders() async throws {
        _ = try await api.news.list(page: 1, perPage: 5)

        let request = try XCTUnwrap(server.receivedRequests.last)
        XCTAssertEqual(request.method, "GET")
        XCTAssertEqual(request.path, "/api/v1/news")
        XCTAssertEqual(request.query, ["page": "1", "per_page": "5"])
        XCTAssertEqual(request.headers["x-api-key"], "secret")
        XCTAssertEqual(request.headers["accept"], "application/json")
    }

    func test_paging_secondPageIsEmpty_andHasNoMore() async throws {
        let page2 = try await api.pages.list(page: 2, perPage: 10)
        XCTAssertTrue(page2.items.isEmpty)
        XCTAssertFalse(page2.hasMore)
        XCTAssertEqual(server.receivedRequests.last?.query["page"], "2")
    }

    func test_languageQueryItemIsSentOnEveryRequest() async throws {
        let localized = API(baseURL: apiBaseURL,
                            session: URLSession(configuration: .ephemeral),
                            queryItems: [URLQueryItem(name: "lang", value: "2")])

        _ = try await localized.news.list(page: 1, perPage: 5)
        _ = try await localized.menus.list()
        _ = try await localized.institutes.list()

        XCTAssertEqual(server.receivedRequests.map { $0.query["lang"] }, ["2", "2", "2"])
        XCTAssertEqual(server.receivedRequests.first?.query["per_page"], "5")
    }

    // MARK: Realistic user journeys

    func test_journey_homeScreenLoadsEverythingInParallel() async throws {
        async let institutes = api.institutes.list()
        async let news = api.news.list()
        async let announcements = api.announcements.list()
        async let pages = api.pages.list()
        async let menus = api.menus.list()

        let (i, n, a, p, m) = try await (institutes, news, announcements, pages, menus)
        XCTAssertEqual(i.count, 2)
        XCTAssertEqual(n.items.count, 2)
        XCTAssertEqual(a.items.count, 2)
        XCTAssertEqual(p.items.count, 2)
        XCTAssertEqual(m.count, 2)
        XCTAssertEqual(server.receivedRequests.count, 5)
    }

    func test_journey_openFirstItemOfEveryList() async throws {
        let institutes = try await api.institutes.list()
        let institute = try await api.institutes.detail(slug: institutes[0].slug)

        let newsList = try await api.news.list()
        let news = try await api.news.detail(permalink: newsList.items[0].permalink ?? "")

        let announcements = try await api.announcements.list()
        let announcement = try await api.announcements.detail(permalink: announcements.items[0].permalink ?? "")

        let pages = try await api.pages.list()
        let page = try await api.pages.detail(permalink: pages.items[0].slug)

        XCTAssertEqual(institute.id, 1)
        XCTAssertEqual(news.id, 4533)
        XCTAssertEqual(announcement.id, 4367)
        XCTAssertEqual(page.id, 39)
        XCTAssertEqual(server.receivedRequests.count, 8)
    }

    // MARK: Error paths over real HTTP

    func test_notFound() async {
        let error = await captureError { try await api.institutes.detail(slug: "nope") }
        XCTAssertEqual(error as? NetworkError, .notFound)
    }

    func test_serverError() async {
        let error = await captureError { try await api.news.detail(permalink: "server-error") }
        XCTAssertEqual(error as? NetworkError,
                       .serverError(statusCode: 500, body: Fixtures.data(#"{"error": "boom"}"#)))
    }

    func test_unauthorized() async {
        let error = await captureError { try await api.pages.detail(permalink: "unauthorized") }
        XCTAssertEqual(error as? NetworkError, .unauthorized)
    }

    func test_malformedJSON() async {
        let error = await captureError { try await api.pages.detail(permalink: "broken-json") }
        guard case .decoding? = error as? NetworkError else {
            return XCTFail("Expected decoding error, got \(String(describing: error))")
        }
    }

    func test_wrongShapeJSON_reportsKeyPath() async {
        let error = await captureError { try await api.pages.detail(permalink: "wrong-shape") }
        guard case .decoding(let message)? = error as? NetworkError else {
            return XCTFail("Expected decoding error, got \(String(describing: error))")
        }
        XCTAssertTrue(message.contains("data.id"), message)
    }

    func test_timeout() async {
        let client = APIClient(baseURL: apiBaseURL,
                               http: URLSessionHTTPClient(session: URLSession(configuration: .ephemeral)),
                               timeout: 0.5)
        let slowAPI = API(client: client)

        let error = await captureError { try await slowAPI.announcements.detail(permalink: "slow-one") }   // server waits 2 s
        XCTAssertEqual(error as? NetworkError, .transport(.timedOut))
    }

    func test_serverDown_isTransportError() async {
        server.stop()
        try? await Task.sleep(nanoseconds: 200_000_000)

        let error = await captureError { try await api.institutes.list() }
        guard case .transport? = error as? NetworkError else {
            return XCTFail("Expected transport error, got \(String(describing: error))")
        }
    }
}
