import XCTest
import TestSupport
@testable import NetworkLayer

final class APIClientTests: XCTestCase {
    private let base = URL(string: "https://api.example.com/v1")!

    private func makeSUT(_ http: MockHTTPClient, timeout: TimeInterval = 30) -> APIClient {
        APIClient(baseURL: base, http: http, defaultHeaders: ["Accept": "application/json"], timeout: timeout)
    }

    func test_request_decodesSuccessfulResponse() async throws {
        let http = MockHTTPClient.responding(json: Fixtures.pagesList)
        let pages = try await makeSUT(http).request(.pages(), as: [Page].self)
        XCTAssertEqual(pages.map(\.slug), ["sustainability", "international"])
    }

    func test_request_sendsExpectedURLRequest() async throws {
        let http = MockHTTPClient.responding(json: Fixtures.pagesList)
        _ = try await makeSUT(http, timeout: 9).request(.pages(page: 3, perPage: 10), as: [Page].self)

        let request = try XCTUnwrap(http.requests.first)
        XCTAssertEqual(request.url?.absoluteString, "https://api.example.com/v1/pages?page=3&per_page=10")
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
        XCTAssertEqual(request.timeoutInterval, 9)
    }

    func test_request_sendsDefaultQueryItemsOnEveryRequest() async throws {
        let http = MockHTTPClient.responding(json: Fixtures.pagesList)
        let client = APIClient(baseURL: base, http: http, defaultQueryItems: [URLQueryItem(name: "lang", value: "2")])

        _ = try await client.request(.pages(page: 1, perPage: 10), as: [Page].self)
        _ = try await client.request(.menus(), as: [Page].self)

        XCTAssertEqual(http.requests.map { $0.url?.absoluteString },
                       ["https://api.example.com/v1/pages?page=1&per_page=10&lang=2",
                        "https://api.example.com/v1/menus?lang=2"])
    }

    func test_request_mapsHTTPStatusCodesToErrors() async {
        let cases: [(Int, NetworkError)] = [
            (401, .unauthorized),
            (403, .unauthorized),
            (404, .notFound),
            (422, .clientError(statusCode: 422, body: Fixtures.data("{}"))),
            (500, .serverError(statusCode: 500, body: Fixtures.data("{}"))),
            (503, .serverError(statusCode: 503, body: Fixtures.data("{}"))),
        ]
        for (status, expected) in cases {
            let http = MockHTTPClient.responding(status: status, json: "{}")
            let error = await captureError { try await makeSUT(http).request(.pages(), as: [Page].self) }
            XCTAssertEqual(error as? NetworkError, expected, "status \(status)")
        }
    }

    func test_request_malformedJSON_throwsDecodingError() async {
        let http = MockHTTPClient.responding(json: Fixtures.malformedJSON)
        let error = await captureError { try await makeSUT(http).request(.page(permalink: "about"), as: PageDetail.self) }
        guard case .decoding? = error as? NetworkError else {
            return XCTFail("Expected decoding error, got \(String(describing: error))")
        }
    }

    func test_request_wrongShape_reportsOffendingKeyPath() async {
        let http = MockHTTPClient.responding(json: Fixtures.wrongShape)
        let error = await captureError { try await makeSUT(http).request(.page(permalink: "about"), as: PageDetail.self) }
        guard case .decoding(let message)? = error as? NetworkError else {
            return XCTFail("Expected decoding error, got \(String(describing: error))")
        }
        XCTAssertTrue(message.contains("id"), message)
    }

    func test_request_missingRequiredKey_isReported() async {
        let http = MockHTTPClient.responding(json: #"{"id": 1, "slug": "about"}"#)   // no title/content
        let error = await captureError { try await makeSUT(http).request(.page(permalink: "about"), as: PageDetail.self) }
        guard case .decoding(let message)? = error as? NetworkError else {
            return XCTFail("Expected decoding error, got \(String(describing: error))")
        }
        XCTAssertTrue(message.contains("Missing key"), message)
    }

    func test_request_propagatesTransportErrors() async {
        let http = MockHTTPClient { _ in throw NetworkError.transport(.notConnectedToInternet) }
        let error = await captureError { try await makeSUT(http).request(.pages(), as: [Page].self) }
        XCTAssertEqual(error as? NetworkError, .transport(.notConnectedToInternet))
    }
}
