import XCTest
import TestSupport
@testable import NetworkLayer

/// Integration tests wire the REAL stack together:
///   API facade → Service → APIClient → URLSessionHTTPClient → URLSession → (stubbed transport) → JSONDecoder
/// Only the socket is replaced (via `URLProtocolStub`), so no network is needed and runs are deterministic.
private func respond(status: Int = 200, json: String, for request: URLRequest) -> (HTTPURLResponse, Data) {
    (HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: "HTTP/1.1",
                     headerFields: ["Content-Type": "application/json"])!,
     Fixtures.data(json))
}

final class APIIntegrationTests: XCTestCase {
    private let baseURL = URL(string: "https://api.example.com/v1")!
    private var api: API!

    override func setUp() {
        super.setUp()
        URLProtocolStub.reset()
        api = API(baseURL: baseURL,
                  session: URLProtocolStub.makeSession(),
                  headers: ["Accept": "application/json", "Authorization": "Bearer test-token"])
    }

    override func tearDown() {
        URLProtocolStub.reset()
        api = nil
        super.tearDown()
    }

    // MARK: Helpers

    /// Routes by path, like a tiny back-end.
    private func stubBackend() {
        URLProtocolStub.handler = { request in
            let ok = { (payload: String, meta: String?) in
                respond(json: Fixtures.envelope(payload, meta: meta), for: request)
            }
            switch request.url!.path {
            case "/v1/institutes":         return ok(Fixtures.institutesList, nil)
            case "/v1/institutes/sociopolitics":       return ok(Fixtures.instituteDetail, nil)
            case "/v1/news":               return ok(Fixtures.newsList, Fixtures.newsMeta)
            case "/v1/news/rus-lit-conf26":          return ok(Fixtures.newsDetail, nil)
            case "/v1/anons":      return ok(Fixtures.announcementsList, Fixtures.announcementsMeta)
            case "/v1/anons/conference-2026": return ok(Fixtures.announcementDetail, nil)
            case "/v1/pages":              return ok(Fixtures.pagesList, Fixtures.pagesMeta)
            case "/v1/pages/sustainability":           return ok(Fixtures.pageDetail, nil)
            case "/v1/menus":              return ok(Fixtures.menusList, nil)
            case "/v1/statistics":         return ok(Fixtures.statisticsList, nil)
            case "/v1/courses":            return respond(json: Fixtures.envelope(Fixtures.coursesList, title: "Курсы"), for: request)
            case "/v1/categories":         return respond(json: Fixtures.envelope(Fixtures.categoriesList, title: "Категории"), for: request)
            default:                       return respond(status: 404, json: Fixtures.notFoundBody, for: request)
            }
        }
    }

    // MARK: Happy paths

    func test_institutes_listAndDetail() async throws {
        stubBackend()
        let institutes = try await api.institutes.list()
        XCTAssertEqual(institutes.map(\.slug), ["sociopolitics", "imi"])

        let detail = try await api.institutes.detail(slug: institutes[0].slug)
        XCTAssertEqual(detail.departments.count, 2)
    }

    func test_news_listWithPaging_andDetailWithGallery() async throws {
        stubBackend()
        let page = try await api.news.list()
        XCTAssertEqual(page.items.count, 2)
        XCTAssertEqual(page.meta?.total, 351)
        XCTAssertEqual(page.meta?.lastPage, 36)
        XCTAssertTrue(page.hasMore)

        let detail = try await api.news.detail(permalink: page.items[0].permalink ?? "")
        XCTAssertEqual(detail.gallery.count, 2)
    }

    func test_announcements_listAndDetail() async throws {
        stubBackend()
        let page = try await api.announcements.list()
        XCTAssertEqual(page.items.map(\.id), [4367, 3031])
        XCTAssertFalse(page.hasMore)

        let detail = try await api.announcements.detail(permalink: page.items[0].permalink ?? "")
        XCTAssertEqual(detail.title, "XX International Annual Scientific Conference of RAU")
    }

    func test_pages_listAndDetail() async throws {
        stubBackend()
        let page = try await api.pages.list()
        XCTAssertEqual(page.items.map(\.slug), ["sustainability", "international"])
        XCTAssertNotNil(page.items[0].banner)            // URL with spaces survived the full stack

        let detail = try await api.pages.detail(permalink: page.items[0].slug)
        XCTAssertEqual(detail.description, "<p>Our sustainability goals.</p>")
    }

    func test_menus_tree() async throws {
        stubBackend()
        let menus = try await api.menus.list()
        XCTAssertEqual(menus.map(\.name), ["Discover RAU", "Admissions"])
        XCTAssertEqual(menus[0].children.count, 2)
    }

    func test_statistics_courses_categories() async throws {
        stubBackend()
        let statistics = try await api.statistics.list()
        XCTAssertEqual(statistics.map(\.count), [8, 6039, 14101])

        let courses = try await api.courses.list()
        XCTAssertEqual(courses.title, "Курсы")
        XCTAssertEqual(courses.items.map(\.id), [1, 15])

        let categories = try await api.categories.list()
        XCTAssertEqual(categories.title, "Категории")
        XCTAssertEqual(categories.items.first?.url, URL(string: "https://dic.rau.am/"))
    }

    // MARK: Request construction through the real URLSession

    func test_requestsCarryHeadersQueryAndMethod() async throws {
        stubBackend()
        _ = try await api.news.list(page: 3, perPage: 7)

        let request = try XCTUnwrap(URLProtocolStub.requests.first)
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.url?.path, "/v1/news")
        XCTAssertEqual(URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems,
                       [URLQueryItem(name: "page", value: "3"), URLQueryItem(name: "per_page", value: "7")])
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
    }

    // MARK: Failure paths

    func test_notFound_isMappedToNetworkError() async {
        stubBackend()
        let error = await captureError { try await api.pages.detail(permalink: "missing") }
        XCTAssertEqual(error as? NetworkError, .notFound)
    }

    func test_serverError_keepsStatusCodeAndBody() async {
        URLProtocolStub.handler = { request in
            respond(status: 502, json: #"{"error": "bad gateway"}"#, for: request)
        }
        let error = await captureError { try await api.institutes.list() }
        XCTAssertEqual(error as? NetworkError,
                       .serverError(statusCode: 502, body: Fixtures.data(#"{"error": "bad gateway"}"#)))
    }

    func test_unauthorized_isMapped() async {
        URLProtocolStub.handler = { request in respond(status: 401, json: "{}", for: request) }
        let error = await captureError { try await api.news.list() }
        XCTAssertEqual(error as? NetworkError, .unauthorized)
    }

    func test_invalidJSON_isMappedToDecodingError() async {
        URLProtocolStub.handler = { request in respond(json: Fixtures.malformedJSON, for: request) }
        let error = await captureError { try await api.pages.detail(permalink: "sustainability") }
        guard case .decoding? = error as? NetworkError else {
            return XCTFail("Expected decoding error, got \(String(describing: error))")
        }
    }

    func test_offline_isMappedToTransportError() async {
        URLProtocolStub.handler = { _ in throw URLError(.notConnectedToInternet) }
        let error = await captureError { try await api.institutes.list() }
        XCTAssertEqual(error as? NetworkError, .transport(.notConnectedToInternet))
    }

    func test_cancellation_isMappedToCancelled() async {
        URLProtocolStub.handler = { request in
            Thread.sleep(forTimeInterval: 0.5)               // keep the request "in flight"
            return respond(json: Fixtures.envelope(Fixtures.pagesList), for: request)
        }
        let api = try! XCTUnwrap(self.api)
        let task = Task { try await api.pages.list() }
        try? await Task.sleep(nanoseconds: 100_000_000)
        task.cancel()

        let error = await captureError { try await task.value }
        XCTAssertEqual(error as? NetworkError, .cancelled)
    }

    // MARK: Concurrency

    func test_concurrentRequestsAcrossServices_allSucceed() async throws {
        stubBackend()
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
        XCTAssertEqual(URLProtocolStub.requests.count, 5)
    }
}
