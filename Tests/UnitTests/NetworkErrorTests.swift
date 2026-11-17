import XCTest
@testable import NetworkLayer

final class NetworkErrorTests: XCTestCase {
    func test_statusMapping() {
        let body = Data("x".utf8)
        XCTAssertNil(NetworkError.from(statusCode: 200, body: body))
        XCTAssertNil(NetworkError.from(statusCode: 204, body: body))
        XCTAssertEqual(NetworkError.from(statusCode: 401, body: body), .unauthorized)
        XCTAssertEqual(NetworkError.from(statusCode: 403, body: body), .unauthorized)
        XCTAssertEqual(NetworkError.from(statusCode: 404, body: body), .notFound)
        XCTAssertEqual(NetworkError.from(statusCode: 422, body: body), .clientError(statusCode: 422, body: body))
        XCTAssertEqual(NetworkError.from(statusCode: 503, body: body), .serverError(statusCode: 503, body: body))
        XCTAssertEqual(NetworkError.from(statusCode: 302, body: body), .invalidResponse)
    }

    func test_everyCaseHasAUserFacingDescription() {
        let all: [NetworkError] = [
            .invalidURL, .invalidResponse, .unsuccessfulResponse, .unauthorized, .notFound,
            .clientError(statusCode: 400, body: Data()), .serverError(statusCode: 500, body: Data()),
            .decoding("x"), .transport(.timedOut), .cancelled
        ]
        for error in all {
            XCTAssertFalse(error.localizedDescription.isEmpty, "\(error)")
        }
    }
}
