import XCTest
@testable import NetworkLayer

final class EndpointTests: XCTestCase {
    private let base = URL(string: "https://api.example.com")!

    func test_urlRequest_buildsPathAndQuery() throws {
        let request = try Endpoint.news(page: 2, perPage: 5).urlRequest(baseURL: base)
        XCTAssertEqual(request.url?.absoluteString, "https://api.example.com/news?page=2&per_page=5")
        XCTAssertEqual(request.httpMethod, "GET")
    }

    func test_urlRequest_appendsDefaultQueryItems_endpointValuesWin() throws {
        let endpoint = Endpoint(path: "/news", queryItems: [URLQueryItem(name: "page", value: "2")])
        let request = try endpoint.urlRequest(baseURL: base,
                                              defaultQueryItems: [URLQueryItem(name: "lang", value: "2"),
                                                                  URLQueryItem(name: "page", value: "1")])
        XCTAssertEqual(request.url?.absoluteString, "https://api.example.com/news?page=2&lang=2")
    }

    func test_urlRequest_defaultQueryItemsAlone() throws {
        let request = try Endpoint.menus().urlRequest(baseURL: base,
                                                      defaultQueryItems: [URLQueryItem(name: "lang", value: "2")])
        XCTAssertEqual(request.url?.absoluteString, "https://api.example.com/menus?lang=2")
    }

    func test_urlRequest_withoutQueryItems_hasNoQuestionMark() throws {
        let request = try Endpoint.institute(slug: "imi").urlRequest(baseURL: base)
        XCTAssertEqual(request.url?.absoluteString, "https://api.example.com/institutes/imi")
    }

    func test_urlRequest_keepsBasePathPrefix_withAndWithoutTrailingSlash() throws {
        for baseString in ["https://api.example.com/api/v1", "https://api.example.com/api/v1/"] {
            let request = try Endpoint.news().urlRequest(baseURL: URL(string: baseString)!)
            XCTAssertEqual(request.url?.path, "/api/v1/news", "base: \(baseString)")
        }
    }

    func test_urlRequest_pathWithoutLeadingSlash_isNormalised() throws {
        let request = try Endpoint(path: "pages/1").urlRequest(baseURL: base)
        XCTAssertEqual(request.url?.path, "/pages/1")
    }

    func test_urlRequest_endpointHeadersOverrideDefaults() throws {
        let endpoint = Endpoint(path: "/x", headers: ["Accept": "text/plain", "X-Custom": "1"])
        let request = try endpoint.urlRequest(baseURL: base,
                                              defaultHeaders: ["Accept": "application/json", "X-Default": "d"])
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "text/plain")
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-Custom"), "1")
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-Default"), "d")
    }

    func test_urlRequest_setsMethodBodyAndTimeout() throws {
        let body = Data("{}".utf8)
        let request = try Endpoint(path: "/x", method: .post, body: body)
            .urlRequest(baseURL: base, timeout: 12)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.httpBody, body)
        XCTAssertEqual(request.timeoutInterval, 12)
    }

    func test_urlRequest_queryValuesAreEscaped() throws {
        let endpoint = Endpoint(path: "/search", queryItems: [URLQueryItem(name: "q", value: "a b")])
        let request = try endpoint.urlRequest(baseURL: base)
        XCTAssertEqual(request.url?.absoluteString, "https://api.example.com/search?q=a%20b")
    }

    func test_allRoutes_haveExpectedPaths() {
        XCTAssertEqual(Endpoint.institutes().path, "/institutes")
        XCTAssertEqual(Endpoint.institute(slug: "imi").path, "/institutes/imi")
        XCTAssertEqual(Endpoint.news().path, "/news")
        XCTAssertEqual(Endpoint.newsItem(permalink: "rus-lit-conf26").path, "/news/rus-lit-conf26")
        XCTAssertEqual(Endpoint.announcements().path, "/anons")
        XCTAssertEqual(Endpoint.announcement(permalink: "CIS-35").path, "/anons/CIS-35")
        XCTAssertEqual(Endpoint.pages().path, "/pages")
        XCTAssertEqual(Endpoint.menus().path, "/menus")
        XCTAssertEqual(Endpoint.page(permalink: "sveden").path, "/pages/sveden")
    }
}
