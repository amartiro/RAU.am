import Foundation

public struct Institute: Codable, Equatable, Identifiable, Sendable {
    public let id: Int
    public let name: String
    public let slug: String
    public let url: URL?

    private enum CodingKeys: String, CodingKey { case id, name, slug, url }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        slug = try c.decode(String.self, forKey: .slug)
        url = try c.decodeLenientURL(forKey: .url)
    }
}

public struct Department: Codable, Equatable, Identifiable, Sendable {
    public let id: Int
    public let name: String
}

/// ⚠️ The institute-detail response was not provided yet: these fields are a best guess.
public struct InstituteDetail: Codable, Equatable, Identifiable, Sendable {
    public let id: Int
    public let name: String
    public let slug: String?
    public let url: URL?
    public let description: String?
    public let address: String?
    public let email: String?
    public let phone: String?
    public let departments: [Department]

    private enum CodingKeys: String, CodingKey {
        case id, name, slug, url, description, address, email, phone, departments
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        slug = try c.decodeIfPresent(String.self, forKey: .slug)
        url = try c.decodeLenientURL(forKey: .url)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        address = try c.decodeIfPresent(String.self, forKey: .address)
        email = try c.decodeIfPresent(String.self, forKey: .email)
        phone = try c.decodeIfPresent(String.self, forKey: .phone)
        departments = try c.decodeIfPresent([Department].self, forKey: .departments) ?? []
    }
}
