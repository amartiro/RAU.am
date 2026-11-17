import Foundation

/// Language the server used for the response (`"lang": {"id": 2, "code": "en"}`).
public struct APILanguage: Codable, Equatable, Sendable {
    public let id: Int
    public let code: String
    public init(id: Int, code: String) { self.id = id; self.code = code }
}

/// `"meta": {"page": 1, "per_page": 10, "total": 351, "last_page": 36, "has_more": true}`
public struct PageMeta: Codable, Equatable, Sendable {
    public let page: Int
    public let perPage: Int
    public let total: Int
    public let lastPage: Int
    public let hasMore: Bool

    public init(page: Int, perPage: Int, total: Int, lastPage: Int, hasMore: Bool) {
        self.page = page; self.perPage = perPage; self.total = total
        self.lastPage = lastPage; self.hasMore = hasMore
    }
}

/// Envelope every endpoint answers with:
///
///     { "data": <payload>, "meta": {...}?, "success": true, "lang": { "id": 2, "code": "en" } }
public struct APIResponse<Payload: Decodable>: Decodable {
    public let data: Payload
    public let meta: PageMeta?          // only present on paginated lists
    public let title: String?           // section title, present on courses / categories
    public let success: Bool
    public let lang: APILanguage?

    public init(data: Payload, success: Bool = true, lang: APILanguage? = nil, meta: PageMeta? = nil, title: String? = nil) {
        self.data = data; self.success = success; self.lang = lang; self.meta = meta; self.title = title
    }

    private enum CodingKeys: String, CodingKey { case data, meta, title, success, lang }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        data = try c.decode(Payload.self, forKey: .data)
        meta = try c.decodeIfPresent(PageMeta.self, forKey: .meta)
        title = try c.decodeIfPresent(String.self, forKey: .title)
        success = try c.decodeIfPresent(Bool.self, forKey: .success) ?? true
        lang = try c.decodeIfPresent(APILanguage.self, forKey: .lang)
    }
}

extension APIResponse: Equatable where Payload: Equatable {}
extension APIResponse: Sendable where Payload: Sendable {}

/// One page of a list plus the paging info the server sent with it.
public struct Paginated<Item> {
    public let items: [Item]
    public let meta: PageMeta?
    public var hasMore: Bool { meta?.hasMore ?? false }

    public init(items: [Item], meta: PageMeta?) { self.items = items; self.meta = meta }
}
extension Paginated: Equatable where Item: Equatable {}
extension Paginated: Sendable where Item: Sendable {}

/// A list together with the section title the server sends with it (`"title": "Категории"`).
public struct TitledList<Item> {
    public let title: String?
    public let items: [Item]
    public init(title: String?, items: [Item]) { self.title = title; self.items = items }
}
extension TitledList: Equatable where Item: Equatable {}
extension TitledList: Sendable where Item: Sendable {}
