import Foundation

/// Navigation menu node. Top-level items have `parentId == 0`; `children` nests recursively.
public struct MenuItem: Codable, Equatable, Identifiable, Sendable {
    public let id: Int
    public let name: String
    public let link: URL?
    public let url: URL?
    public let parentId: Int
    public let order: Int
    public let children: [MenuItem]

    private enum CodingKeys: String, CodingKey { case id, name, link, url, parentId, order, children }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        link = try c.decodeLenientURL(forKey: .link)
        url = try c.decodeLenientURL(forKey: .url)
        parentId = try c.decodeIfPresent(Int.self, forKey: .parentId) ?? 0
        order = try c.decodeIfPresent(Int.self, forKey: .order) ?? 0
        children = try c.decodeIfPresent([MenuItem].self, forKey: .children) ?? []
    }
}
