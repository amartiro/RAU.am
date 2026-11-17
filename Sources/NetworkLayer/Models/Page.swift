import Foundation

public struct Page: Codable, Equatable, Identifiable, Sendable {
    public let id: Int
    public let title: String
    public let slug: String
    public let shortDescription: String?
    public let banner: URL?
    public let url: URL?
    public let metaKey: String?
    public let metaDescription: String?
    public let updatedAt: Date?

    private enum CodingKeys: String, CodingKey {
        case id, title, slug, shortDescription, banner, url, metaKey, metaDescription, updatedAt
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        slug = try c.decode(String.self, forKey: .slug)
        shortDescription = try c.decodeIfPresent(String.self, forKey: .shortDescription)
        banner = try c.decodeLenientURL(forKey: .banner)
        url = try c.decodeLenientURL(forKey: .url)
        metaKey = try c.decodeIfPresent(String.self, forKey: .metaKey)
        metaDescription = try c.decodeIfPresent(String.self, forKey: .metaDescription)
        updatedAt = try c.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
}

/// ⚠️ The page-detail response was not provided yet: the body is read from `description` or `content`.
public struct PageDetail: Decodable, Equatable, Identifiable, Sendable {
    public let page: Page
    /// HTML body of the page.
    public let description: String?

    public var id: Int { page.id }
    public var title: String { page.title }
    public var slug: String { page.slug }
    public var updatedAt: Date? { page.updatedAt }

    private enum CodingKeys: String, CodingKey { case description, content }

    public init(from decoder: Decoder) throws {
        page = try Page(from: decoder)
        let c = try decoder.container(keyedBy: CodingKeys.self)
        description = try c.decodeIfPresent(String.self, forKey: .description)
            ?? c.decodeIfPresent(String.self, forKey: .content)
    }
}
