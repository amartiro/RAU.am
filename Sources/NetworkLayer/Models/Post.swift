import Foundation

/// News and announcements ("anons") share one shape; `group` tells them apart (`"news"` / `"anons"`).
public struct Post: Codable, Equatable, Identifiable, Sendable {
    public let id: Int
    public let group: String
    public let title: String
    public let subtitle: String?
    /// HTML.
    public let description: String?
    public let image: URL?
    public let banner: URL?
    public let date: Date
    public let eventDate: Date?
    /// A slug (`"rus-lit-conf26"`) or, for external items, a full URL string.
    public let permalink: String?
    public let url: URL?
    public let link: URL?

    private enum CodingKeys: String, CodingKey {
        case id, group, title, subtitle, description, image, banner, date, eventDate, permalink, url, link
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        group = try c.decodeIfPresent(String.self, forKey: .group) ?? ""
        title = try c.decode(String.self, forKey: .title)
        subtitle = try c.decodeIfPresent(String.self, forKey: .subtitle)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        image = try c.decodeLenientURL(forKey: .image)
        banner = try c.decodeLenientURL(forKey: .banner)
        date = try c.decode(Date.self, forKey: .date)
        eventDate = try? c.decodeIfPresent(Date.self, forKey: .eventDate)   // tolerate unknown formats
        permalink = try c.decodeIfPresent(String.self, forKey: .permalink)
        url = try c.decodeLenientURL(forKey: .url)
        link = try c.decodeLenientURL(forKey: .link)
    }
}

public struct GalleryImage: Codable, Equatable, Identifiable, Sendable {
    public let id: Int
    public let url: URL

    private enum CodingKeys: String, CodingKey { case id, url }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        guard let parsed = try c.decodeLenientURL(forKey: .url) else {
            throw DecodingError.dataCorruptedError(forKey: .url, in: c, debugDescription: "Invalid gallery URL")
        }
        url = parsed
    }
}

/// A post plus its photo gallery (`GET …/{id}`). The JSON is flat; `post` holds the common fields.
public struct PostDetail: Decodable, Equatable, Identifiable, Sendable {
    public let post: Post
    public let gallery: [GalleryImage]

    public var id: Int { post.id }
    public var title: String { post.title }
    public var subtitle: String? { post.subtitle }
    public var description: String? { post.description }
    public var date: Date { post.date }
    public var url: URL? { post.url }

    private enum CodingKeys: String, CodingKey { case gallery }

    public init(from decoder: Decoder) throws {
        post = try Post(from: decoder)
        let c = try decoder.container(keyedBy: CodingKeys.self)
        gallery = try c.decodeIfPresent([GalleryImage].self, forKey: .gallery) ?? []
    }
}

public typealias News = Post
public typealias NewsDetail = PostDetail
public typealias Announcement = Post
public typealias AnnouncementDetail = PostDetail
