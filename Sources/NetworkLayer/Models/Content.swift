import Foundation

/// `GET /statistics` – numbers shown on the home page (`{"count": 8, "title": "Институтов"}`).
public struct Statistic: Codable, Equatable, Identifiable, Sendable {
    public let count: Int
    public let title: String
    public var id: String { title }
}

/// `GET /courses` – "Courses and sections" cards.
public struct Course: Codable, Equatable, Identifiable, Sendable {
    public let id: Int
    public let name: String
    public let subtitle: String?
    public let image: URL?
    public let link: URL?
    public let url: URL?
    public let order: Int

    private enum CodingKeys: String, CodingKey { case id, name, subtitle, image, link, url, order }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        subtitle = try c.decodeIfPresent(String.self, forKey: .subtitle)
        image = try c.decodeLenientURL(forKey: .image)
        link = try c.decodeLenientURL(forKey: .link)
        url = try c.decodeLenientURL(forKey: .url)
        order = try c.decodeIfPresent(Int.self, forKey: .order) ?? 0
    }
}

/// `GET /categories` – the home page's quick-link tiles.
public struct SiteCategory: Codable, Equatable, Identifiable, Sendable {
    public let id: Int
    public let name: String
    public let icon: URL?
    public let link: URL?
    public let url: URL?
    public let order: Int

    private enum CodingKeys: String, CodingKey { case id, name, icon, link, url, order }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        icon = try c.decodeLenientURL(forKey: .icon)
        link = try c.decodeLenientURL(forKey: .link)
        url = try c.decodeLenientURL(forKey: .url)
        order = try c.decodeIfPresent(Int.self, forKey: .order) ?? 0
    }
}
