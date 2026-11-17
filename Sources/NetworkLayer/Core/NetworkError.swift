import Foundation

/// Every failure the network layer can surface to callers.
public enum NetworkError: Error, Equatable {
    case invalidURL
    case invalidResponse
    case unsuccessfulResponse               // envelope said "success": false
    case unauthorized                       // 401 / 403
    case notFound                           // 404
    case clientError(statusCode: Int, body: Data)   // other 4xx
    case serverError(statusCode: Int, body: Data)   // 5xx
    case decoding(String)                   // human readable decoding failure
    case transport(URLError.Code)           // no connection, timeout, ...
    case cancelled

    /// Maps an HTTP status code to an error (nil when the status is a success).
    static func from(statusCode: Int, body: Data) -> NetworkError? {
        switch statusCode {
        case 200..<300: return nil
        case 401, 403:  return .unauthorized
        case 404:       return .notFound
        case 400..<500: return .clientError(statusCode: statusCode, body: body)
        case 500..<600: return .serverError(statusCode: statusCode, body: body)
        default:        return .invalidResponse
        }
    }
}

extension NetworkError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "The request URL is invalid."
        case .invalidResponse: return "The server returned an invalid response."
        case .unsuccessfulResponse: return "The server reported that the request was not successful."
        case .unauthorized: return "You are not authorized to perform this request."
        case .notFound: return "The requested resource was not found."
        case .clientError(let code, _): return "Request failed with status \(code)."
        case .serverError(let code, _): return "Server error (\(code))."
        case .decoding(let message): return "Could not read the server response: \(message)"
        case .transport(let code): return "Network error (\(code.rawValue))."
        case .cancelled: return "The request was cancelled."
        }
    }
}
