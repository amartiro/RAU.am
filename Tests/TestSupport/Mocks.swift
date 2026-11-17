import Foundation
import NetworkLayer

public extension HTTPURLResponse {
    static func stub(url: URL = URL(string: "https://example.com")!, status: Int = 200) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: nil)!
    }
}

/// Replaces the lowest layer (URLSession) – used by unit tests of `APIClient`.
public final class MockHTTPClient: HTTPClient, @unchecked Sendable {
    public typealias Handler = (URLRequest) throws -> (Data, HTTPURLResponse)

    private let lock = NSLock()
    private var _requests: [URLRequest] = []
    public var handler: Handler

    public init(handler: @escaping Handler = { _ in (Data(), .stub()) }) {
        self.handler = handler
    }

    public static func responding(status: Int = 200, json: String) -> MockHTTPClient {
        MockHTTPClient { request in
            (Fixtures.data(json), .stub(url: request.url ?? URL(string: "https://example.com")!, status: status))
        }
    }

    public var requests: [URLRequest] {
        lock.lock(); defer { lock.unlock() }
        return _requests
    }

    public func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        lock.lock(); _requests.append(request); lock.unlock()
        return try handler(request)
    }
}

/// Replaces the `APIClient` – used by unit tests of the services.
public final class MockAPIClient: APIClientProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var _endpoints: [Endpoint] = []
    public var handler: (Endpoint) throws -> Any

    public init(handler: @escaping (Endpoint) throws -> Any = { _ in throw NetworkError.invalidResponse }) {
        self.handler = handler
    }

    public var endpoints: [Endpoint] {
        lock.lock(); defer { lock.unlock() }
        return _endpoints
    }

    public func request<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T {
        lock.lock(); _endpoints.append(endpoint); lock.unlock()
        guard let value = try handler(endpoint) as? T else {
            throw NetworkError.decoding("MockAPIClient returned a value that is not \(T.self)")
        }
        return value
    }
}
