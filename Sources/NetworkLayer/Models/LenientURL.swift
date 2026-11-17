import Foundation

extension URL {
    /// The API sometimes returns links containing spaces or brackets (e.g. `.../page/55 (1)abc.jpg`).
    /// `URL(string:)` rejects those on older OS versions, so we fall back to percent-encoding.
    /// Returns nil for empty / unparsable strings instead of failing the whole response.
    static func lenient(_ string: String) -> URL? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let url = URL(string: trimmed) { return url }
        guard let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
        return URL(string: encoded)
    }
}

extension KeyedDecodingContainer {
    /// Decodes an optional link without ever throwing because of its format.
    func decodeLenientURL(forKey key: Key) throws -> URL? {
        guard let string = try decodeIfPresent(String.self, forKey: key) else { return nil }
        return URL.lenient(string)
    }
}
