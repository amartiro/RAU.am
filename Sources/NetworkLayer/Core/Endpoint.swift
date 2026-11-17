import Foundation

public struct Endpoint: Equatable, Sendable {
    public enum Method: String, Sendable {
        case get = "GET", post = "POST", put = "PUT", patch = "PATCH", delete = "DELETE"
    }

    public let path: String
    public let method: Method
    public let queryItems: [URLQueryItem]
    public let headers: [String: String]
    public let body: Data?

    public init(path: String,
                method: Method = .get,
                queryItems: [URLQueryItem] = [],
                headers: [String: String] = [:],
                body: Data? = nil) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.headers = headers
        self.body = body
    }

    /// Builds a `URLRequest` relative to `baseURL`. The base URL may contain a path prefix (e.g. `/api/v1`).
    /// `defaultQueryItems` (e.g. `lang=2`) are appended to every request unless the endpoint sets the same name itself.
    public func urlRequest(baseURL: URL,
                           defaultHeaders: [String: String] = [:],
                           defaultQueryItems: [URLQueryItem] = [],
                           timeout: TimeInterval = 30) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw NetworkError.invalidURL
        }
        let basePath = components.path.hasSuffix("/") ? String(components.path.dropLast()) : components.path
        let endpointPath = path.hasPrefix("/") ? path : "/" + path
        components.path = basePath + endpointPath
        let inherited = defaultQueryItems.filter { item in !queryItems.contains { $0.name == item.name } }
        let allQueryItems = queryItems + inherited
        components.queryItems = allQueryItems.isEmpty ? nil : allQueryItems

        guard let url = components.url else { throw NetworkError.invalidURL }

        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: timeout)
        request.httpMethod = method.rawValue
        request.httpBody = body
        let merged = defaultHeaders.merging(headers) { _, endpointValue in endpointValue }
        for (field, value) in merged {
            request.setValue(value, forHTTPHeaderField: field)
        }
        return request
    }
}
