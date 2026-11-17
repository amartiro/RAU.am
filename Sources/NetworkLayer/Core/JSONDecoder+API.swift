import Foundation

extension JSONDecoder {
    /// Decoder configured for the API: snake_case keys and ISO-8601 dates
    /// (with or without fractional seconds).
    public static func api() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)

            let withFraction = ISO8601DateFormatter()
            withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = withFraction.date(from: string) { return date }

            let plain = ISO8601DateFormatter()
            plain.formatOptions = [.withInternetDateTime]
            if let date = plain.date(from: string) { return date }

            throw DecodingError.dataCorruptedError(in: container,
                                                   debugDescription: "Invalid ISO-8601 date: \(string)")
        }
        return decoder
    }
}
