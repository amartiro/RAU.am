import Foundation

/// All API routes in one place. Changing a path only requires editing this file.
extension Endpoint {
    private static func paging(page: Int, perPage: Int) -> [URLQueryItem] {
        [URLQueryItem(name: "page", value: String(page)),
         URLQueryItem(name: "per_page", value: String(perPage))]
    }

    /// Not paginated: the API returns every institute at once.
    public static func institutes() -> Endpoint { Endpoint(path: "/institutes") }
    public static func institute(slug: String) -> Endpoint { Endpoint(path: "/institutes/\(slug)") }

    public static func news(page: Int = 1, perPage: Int = 10) -> Endpoint {
        Endpoint(path: "/news", queryItems: paging(page: page, perPage: perPage))
    }
    public static func newsItem(permalink: String) -> Endpoint { Endpoint(path: "/news/\(permalink)") }

    public static func announcements(page: Int = 1, perPage: Int = 10) -> Endpoint {
        Endpoint(path: "/anons", queryItems: paging(page: page, perPage: perPage))
    }
    public static func announcement(permalink: String) -> Endpoint { Endpoint(path: "/anons/\(permalink)") }

    public static func pages(page: Int = 1, perPage: Int = 10) -> Endpoint {
        Endpoint(path: "/pages", queryItems: paging(page: page, perPage: perPage))
    }
    public static func page(permalink: String) -> Endpoint { Endpoint(path: "/pages/\(permalink)") }

    public static func menus() -> Endpoint { Endpoint(path: "/menus") }
    public static func statistics() -> Endpoint { Endpoint(path: "/statistics") }
    public static func courses() -> Endpoint { Endpoint(path: "/courses") }
    public static func categories() -> Endpoint { Endpoint(path: "/categories") }
}
