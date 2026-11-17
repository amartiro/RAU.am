import XCTest
import TestSupport
@testable import NetworkLayer

final class ModelDecodingTests: XCTestCase {
    private let decoder = JSONDecoder.api()

    private func decode<T: Decodable>(_ json: String) throws -> T {
        try decoder.decode(T.self, from: Fixtures.data(json))
    }

    // MARK: Institutes
    func test_institutes_list() throws {
        let items: [Institute] = try decode(Fixtures.institutesList)
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].id, 1)
        XCTAssertEqual(items[0].name, "Institute of International Relations and Socio-Political Science")
        XCTAssertEqual(items[0].slug, "sociopolitics")
        XCTAssertEqual(items[0].url, URL(string: "https://sociopolitics.rau.am"))
        XCTAssertEqual(items[1].slug, "imi")
    }

    func test_institute_urlIsOptional() throws {
        let item: Institute = try decode(#"{"id": 9, "name": "No site", "slug": "none"}"#)
        XCTAssertNil(item.url)
    }

    func test_instituteDetail_full_andMinimal() throws {
        let detail: InstituteDetail = try decode(Fixtures.instituteDetail)
        XCTAssertEqual(detail.slug, "sociopolitics")
        XCTAssertEqual(detail.departments.map(\.name), ["Political Science", "History"])

        let minimal: InstituteDetail = try decode(Fixtures.instituteDetailMinimal)
        XCTAssertTrue(minimal.departments.isEmpty)
        XCTAssertNil(minimal.address)
    }

    // MARK: News
    func test_news_list() throws {
        let items: [News] = try decode(Fixtures.newsList)
        XCTAssertEqual(items.map(\.id), [4533, 4530])

        let first = items[0]
        XCTAssertEqual(first.group, "news")
        XCTAssertEqual(first.title, "International Conference “Russian Literature in a Changing World” Opens at RAU")
        XCTAssertEqual(first.subtitle, "Over the course of two days, participants will present more than 50 papers.")
        XCTAssertEqual(first.description, "<div>The annual conference opened on October 15.</div>")
        XCTAssertEqual(first.image, URL(string: "https://rau.am/uploads/post/image/1792053748_1--1.jpg"))
        XCTAssertEqual(first.date, Fixtures.date("2026-10-15T08:42:28Z"))      // "+00:00" offset form
        XCTAssertNil(first.eventDate)
        XCTAssertEqual(first.permalink, "rus-lit-conf26")
        XCTAssertEqual(first.url, URL(string: "https://rau.am/en/news/rus-lit-conf26"))
        XCTAssertNil(first.link)

        XCTAssertNil(items[1].subtitle)
        XCTAssertNil(items[1].description)
        XCTAssertNil(items[1].image)
    }

    func test_newsDetail_hasGallery() throws {
        let detail: NewsDetail = try decode(Fixtures.newsDetail)
        XCTAssertEqual(detail.id, 4533)
        XCTAssertEqual(detail.title, "International Conference “Russian Literature in a Changing World” Opens at RAU")
        XCTAssertEqual(detail.gallery.map(\.id), [19440, 19441])
        XCTAssertEqual(detail.gallery[0].url,
                       URL(string: "https://rau.am/uploads/post/gallery/1792053691_photo_5368488535234648796_w.jpg"))
    }

    // MARK: Announcements ("anons")
    func test_announcements_list_externalPermalinkAndNullDescription() throws {
        let items: [Announcement] = try decode(Fixtures.announcementsList)
        XCTAssertEqual(items.map(\.group), ["anons", "anons"])
        XCTAssertEqual(items[0].permalink, "conference-2026")
        XCTAssertEqual(items[1].permalink, "https://dic.rau.am/en/tab-page/3821647162-open-calls")
        XCTAssertNil(items[1].description)
    }

    func test_announcementDetail_withoutGallery_defaultsToEmpty() throws {
        let detail: AnnouncementDetail = try decode(Fixtures.announcementDetail)
        XCTAssertEqual(detail.id, 4367)
        XCTAssertTrue(detail.gallery.isEmpty)
    }

    // MARK: Pages
    func test_pages_list_toleratesSpacesInBannerURL() throws {
        let items: [Page] = try decode(Fixtures.pagesList)
        XCTAssertEqual(items.map(\.slug), ["sustainability", "international"])
        XCTAssertNotNil(items[0].banner, "a banner URL containing spaces/brackets must still decode")
        XCTAssertTrue(items[0].banner?.absoluteString.hasPrefix("https://rau.am/uploads/page/55") ?? false)
        XCTAssertNil(items[0].shortDescription)
        XCTAssertEqual(items[0].updatedAt, Fixtures.date("2026-07-14T05:42:24Z"))
        XCTAssertEqual(items[1].metaKey, "International Cooperation")
    }

    func test_pageDetail_readsDescription() throws {
        let detail: PageDetail = try decode(Fixtures.pageDetail)
        XCTAssertEqual(detail.id, 39)
        XCTAssertEqual(detail.description, "<p>Our sustainability goals.</p>")
    }

    func test_pageDetail_fallsBackToContentKey() throws {
        let detail: PageDetail = try decode(#"{"id": 1, "title": "t", "slug": "s", "content": "<p>c</p>"}"#)
        XCTAssertEqual(detail.description, "<p>c</p>")
    }

    // MARK: Menus
    func test_menus_tree() throws {
        let menus: [MenuItem] = try decode(Fixtures.menusList)
        XCTAssertEqual(menus.map(\.name), ["Discover RAU", "Admissions"])
        XCTAssertNil(menus[0].link)
        XCTAssertNil(menus[0].url)
        XCTAssertEqual(menus[0].parentId, 0)
        XCTAssertEqual(menus[0].order, 2)
        XCTAssertEqual(menus[0].children.map(\.id), [133, 132])
        XCTAssertEqual(menus[0].children[0].parentId, 28)
        XCTAssertEqual(menus[0].children[0].url, URL(string: "https://rector.rau.am/en"))
        XCTAssertTrue(menus[0].children[0].children.isEmpty)
    }

    func test_menu_missingChildren_defaultsToEmpty() throws {
        let item: MenuItem = try decode(#"{"id": 1, "name": "x", "parent_id": 0, "order": 1}"#)
        XCTAssertTrue(item.children.isEmpty)
    }

    // MARK: Resilience
    func test_unknownEventDateFormat_isIgnoredInsteadOfFailing() throws {
        let post: Post = try decode(#"{"id": 1, "title": "t", "date": "2024-01-01T00:00:00Z", "event_date": "next Friday"}"#)
        XCTAssertNil(post.eventDate)
    }

    func test_invalidMainDate_throws() {
        XCTAssertThrowsError(try decode(#"{"id": 1, "title": "t", "date": "yesterday"}"#) as Post)
    }

    func test_lenientURL() {
        XCTAssertNotNil(URL.lenient("https://x.com/a b (1).jpg"))
        XCTAssertEqual(URL.lenient("https://x.com/ok"), URL(string: "https://x.com/ok"))
        XCTAssertNil(URL.lenient(""))
        XCTAssertNil(URL.lenient("   "))
    }

    func test_emptyList_decodesToEmptyArray() throws {
        let items: [News] = try decode("[]")
        XCTAssertTrue(items.isEmpty)
    }
}
