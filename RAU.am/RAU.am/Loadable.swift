import Foundation
import NetworkLayer

enum Loadable<Value> {
    case idle
    case loading
    case loaded(Value)
    case failed(String)

    var value: Value? {
        if case .loaded(let value) = self { return value }
        return nil
    }

    /// Runs `work` and maps the outcome. Cancellation returns `.idle` so callers can ignore it.
    static func capture(_ work: () async throws -> Value) async -> Loadable<Value> {
        do {
            return .loaded(try await work())
        } catch let error as NetworkError where error == .cancelled {
            return .idle
        } catch {
            return .failed(error.localizedDescription)
        }
    }
}
