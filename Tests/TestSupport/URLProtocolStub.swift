import Foundation

/// Intercepts requests made by a *real* `URLSession`, so integration tests exercise the real
/// URLSession → HTTPClient → APIClient → Service → Decoder chain without any socket.
public final class URLProtocolStub: URLProtocol {
    public typealias Handler = (URLRequest) throws -> (HTTPURLResponse, Data)

    private static let lock = NSLock()
    private static var _handler: Handler?
    private static var _requests: [URLRequest] = []

    public static var handler: Handler? {
        get { lock.lock(); defer { lock.unlock() }; return _handler }
        set { lock.lock(); _handler = newValue; lock.unlock() }
    }

    public static var requests: [URLRequest] {
        lock.lock(); defer { lock.unlock() }
        return _requests
    }

    public static func reset() {
        lock.lock(); _handler = nil; _requests = []; lock.unlock()
    }

    /// A URLSession whose traffic is routed through this stub.
    public static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return URLSession(configuration: configuration)
    }

    public override class func canInit(with request: URLRequest) -> Bool { true }
    public override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    public override func startLoading() {
        Self.lock.lock(); Self._requests.append(request); Self.lock.unlock()

        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    public override func stopLoading() {}
}
