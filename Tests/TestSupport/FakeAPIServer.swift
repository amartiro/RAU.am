import Foundation

/// A fake back-end that behaves like the real API (served under `/api/v1`).
///
/// Special routes used by the error-path tests:
///  - `/institutes/nope`   → 404
///  - `/news/server-error` → 500
///  - `/pages/unauthorized` → 401
///  - `/pages/broken-json` → 200 with truncated JSON
///  - `/pages/wrong-shape` → 200 with valid JSON of the wrong shape
///  - `/anons/slow-one` → 200 but answers after 2 s (timeout tests)
///  - `?page=2` on any list returns an empty page with `has_more: false`
public enum FakeAPIServer {
    public static let prefix = "/api/v1"

    public static func makeServer() -> LocalHTTPServer {
        LocalHTTPServer(handler: route)
    }

    private static func list(_ payload: String, meta: String, page2: Bool) -> ServerResponse {
        if page2 {
            return .json(Fixtures.envelope("[]", meta: Fixtures.meta(page: 2, total: 0, lastPage: 1, hasMore: false)))
        }
        return .json(Fixtures.envelope(payload, meta: meta))
    }

    @Sendable
    public static func route(_ request: ServerRequest) -> ServerResponse {
        guard request.method == "GET", request.path.hasPrefix(prefix) else {
            return .json(Fixtures.notFoundBody, status: 404)
        }
        let path = String(request.path.dropFirst(prefix.count))
        let page2 = request.query["page"] == "2"

        switch path {
        case "/institutes":     return .json(Fixtures.envelope(Fixtures.institutesList))      // not paginated
        case "/institutes/sociopolitics": return .json(Fixtures.envelope(Fixtures.instituteDetail))
        case "/institutes/imi": return .json(Fixtures.envelope(Fixtures.instituteDetailMinimal))
        case "/institutes/nope": return .json(Fixtures.notFoundBody, status: 404)

        case "/news":           return list(Fixtures.newsList, meta: Fixtures.newsMeta, page2: page2)
        case "/news/rus-lit-conf26": return .json(Fixtures.envelope(Fixtures.newsDetail))
        case "/news/server-error": return .json(#"{"error": "boom"}"#, status: 500)

        case "/anons":     return list(Fixtures.announcementsList, meta: Fixtures.announcementsMeta, page2: page2)
        case "/anons/conference-2026": return .json(Fixtures.envelope(Fixtures.announcementDetail))
        case "/anons/slow-one":  return .json(Fixtures.envelope(Fixtures.announcementDetail), delay: 2)

        case "/pages":          return list(Fixtures.pagesList, meta: Fixtures.pagesMeta, page2: page2)
        case "/pages/sustainability": return .json(Fixtures.envelope(Fixtures.pageDetail))
        case "/pages/unauthorized": return .json(#"{"error": "unauthorized"}"#, status: 401)
        case "/pages/broken-json": return .json(Fixtures.malformedJSON)
        case "/pages/wrong-shape": return .json(Fixtures.wrongShape)

        case "/menus":          return .json(Fixtures.envelope(Fixtures.menusList))
        case "/statistics":     return .json(Fixtures.envelope(Fixtures.statisticsList))
        case "/courses":        return .json(Fixtures.envelope(Fixtures.coursesList, title: "Курсы и Разделы"))
        case "/categories":     return .json(Fixtures.envelope(Fixtures.categoriesList, title: "Категории"))

        default:                return .json(Fixtures.notFoundBody, status: 404)
        }
    }
}
