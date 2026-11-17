import Foundation
import Network

public struct ServerRequest: Sendable {
    public let method: String
    public let path: String
    public let query: [String: String]
    public let headers: [String: String]   // lower-cased keys
}

public struct ServerResponse: Sendable {
    public var status: Int
    public var body: Data
    public var delay: TimeInterval

    public init(status: Int = 200, body: Data, delay: TimeInterval = 0) {
        self.status = status; self.body = body; self.delay = delay
    }

    public static func json(_ json: String, status: Int = 200, delay: TimeInterval = 0) -> ServerResponse {
        ServerResponse(status: status, body: Data(json.utf8), delay: delay)
    }
}

/// A tiny real HTTP server bound to the loopback interface (127.0.0.1) on a random free port.
/// Lets end-to-end tests run real sockets + real URLSession with no external dependency.
public final class LocalHTTPServer: @unchecked Sendable {
    public enum ServerError: Error { case failedToStart }

    private final class ResumeBox { var done = false }

    private let queue = DispatchQueue(label: "LocalHTTPServer")
    private let lock = NSLock()
    private var listener: NWListener?
    private var _requests: [ServerRequest] = []
    private let handler: @Sendable (ServerRequest) -> ServerResponse

    public private(set) var baseURL = URL(string: "http://127.0.0.1")!

    public init(handler: @escaping @Sendable (ServerRequest) -> ServerResponse) {
        self.handler = handler
    }

    public var receivedRequests: [ServerRequest] {
        lock.lock(); defer { lock.unlock() }
        return _requests
    }

    public func start() async throws {
        let parameters = NWParameters.tcp
        parameters.requiredInterfaceType = .loopback      // avoids the macOS firewall prompt
        let listener = try NWListener(using: parameters, on: .any)
        self.listener = listener
        listener.newConnectionHandler = { [weak self] connection in self?.handle(connection) }

        let box = ResumeBox()
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            listener.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    if !box.done { box.done = true; continuation.resume() }
                case .failed(let error):
                    if !box.done { box.done = true; continuation.resume(throwing: error) }
                case .cancelled:
                    if !box.done { box.done = true; continuation.resume(throwing: ServerError.failedToStart) }
                default:
                    break
                }
            }
            listener.start(queue: queue)
        }

        guard let port = listener.port else { throw ServerError.failedToStart }
        baseURL = URL(string: "http://127.0.0.1:\(port.rawValue)")!
    }

    public func stop() {
        listener?.cancel()
        listener = nil
    }

    // MARK: Connection handling

    private func handle(_ connection: NWConnection) {
        connection.start(queue: queue)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { [weak self] data, _, _, error in
            guard let self = self,
                  error == nil,
                  let data = data,
                  let raw = String(data: data, encoding: .utf8),
                  let request = Self.parse(raw) else {
                connection.cancel()
                return
            }

            self.lock.lock(); self._requests.append(request); self.lock.unlock()

            let response = self.handler(request)
            let send = { Self.write(response, to: connection) }
            if response.delay > 0 {
                self.queue.asyncAfter(deadline: .now() + response.delay, execute: send)
            } else {
                send()
            }
        }
    }

    private static func write(_ response: ServerResponse, to connection: NWConnection) {
        let reason = HTTPURLResponse.localizedString(forStatusCode: response.status)
        let head = "HTTP/1.1 \(response.status) \(reason)\r\n"
            + "Content-Type: application/json; charset=utf-8\r\n"
            + "Content-Length: \(response.body.count)\r\n"
            + "Connection: close\r\n\r\n"
        var payload = Data(head.utf8)
        payload.append(response.body)
        connection.send(content: payload, completion: .contentProcessed { _ in connection.cancel() })
    }

    private static func parse(_ raw: String) -> ServerRequest? {
        let lines = raw.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else { return nil }
        let parts = requestLine.split(separator: " ")
        guard parts.count >= 2, let components = URLComponents(string: String(parts[1])) else { return nil }

        var query: [String: String] = [:]
        for item in components.queryItems ?? [] { query[item.name] = item.value ?? "" }

        var headers: [String: String] = [:]
        for line in lines.dropFirst() {
            if line.isEmpty { break }
            guard let colon = line.firstIndex(of: ":") else { continue }
            let key = line[..<colon].lowercased()
            let value = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
            headers[key] = value
        }
        return ServerRequest(method: String(parts[0]), path: components.path, query: query, headers: headers)
    }
}
