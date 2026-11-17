import Foundation

/// Runs `work` and returns the error it threw (nil if it succeeded).
/// Lets tests assert on async failures without needing XCTest inside this module.
public func captureError<T>(_ work: () async throws -> T) async -> Error? {
    do {
        _ = try await work()
        return nil
    } catch {
        return error
    }
}
