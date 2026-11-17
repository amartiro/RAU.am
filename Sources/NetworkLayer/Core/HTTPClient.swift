import Foundation

/// Lowest layer: sends a request and returns raw data + HTTP response.
/// Abstracted so unit tests can replace it without touching the network.
public protocol HTTPClient: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

public struct URLSessionHTTPClient: HTTPClient, @unchecked Sendable {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }
            return (data, http)
        } catch let error as NetworkError {
            throw error
        } catch let error as URLError {
            throw error.code == .cancelled ? NetworkError.cancelled : NetworkError.transport(error.code)
        } catch is CancellationError {
            throw NetworkError.cancelled
        }
    }
}
