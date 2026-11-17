import Foundation

public protocol APIClientProtocol: Sendable {
    /// Performs the request, validates the status code and decodes the body.
    func request<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T
}

public final class APIClient: APIClientProtocol, @unchecked Sendable {
    private let baseURL: URL
    private let http: HTTPClient
    private let defaultHeaders: [String: String]
    private let defaultQueryItems: [URLQueryItem]
    private let timeout: TimeInterval
    private let decoder: JSONDecoder

    public init(baseURL: URL,
                http: HTTPClient = URLSessionHTTPClient(),
                defaultHeaders: [String: String] = ["Accept": "application/json"],
                defaultQueryItems: [URLQueryItem] = [],
                timeout: TimeInterval = 30,
                decoder: JSONDecoder = .api()) {
        self.baseURL = baseURL
        self.http = http
        self.defaultHeaders = defaultHeaders
        self.defaultQueryItems = defaultQueryItems
        self.timeout = timeout
        self.decoder = decoder
    }

    public func request<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T {
        let urlRequest = try endpoint.urlRequest(baseURL: baseURL,
                                                 defaultHeaders: defaultHeaders,
                                                 defaultQueryItems: defaultQueryItems,
                                                 timeout: timeout)
        let (data, response) = try await http.send(urlRequest)

        if let error = NetworkError.from(statusCode: response.statusCode, body: data) {
            throw error
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch let error as DecodingError {
            throw NetworkError.decoding(Self.describe(error))
        } catch {
            throw NetworkError.decoding(error.localizedDescription)
        }
    }

    private static func describe(_ error: DecodingError) -> String {
        func path(_ context: DecodingError.Context) -> String {
            context.codingPath.map { $0.stringValue }.joined(separator: ".")
        }
        switch error {
        case .keyNotFound(let key, let context):
            return "Missing key '\(key.stringValue)' at '\(path(context))'"
        case .typeMismatch(_, let context), .valueNotFound(_, let context), .dataCorrupted(let context):
            return "\(context.debugDescription) at '\(path(context))'"
        @unknown default:
            return error.localizedDescription
        }
    }
}
