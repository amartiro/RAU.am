import XCTest
import TestSupport
@testable import NetworkLayer

/// Statistics, courses and categories (previously static content on the home page).
final class ContentEndpointsTests: XCTestCase {
    private func decode<T: Decodable>(_ json: String) throws -> T {
        try JSONDecoder.api().decode(T.self, from: Fixtures.data(json))
    }

    func test_endpointPaths() {
        XCTAssertEqual(Endpoint.statistics().path, "/statistics")
        XCTAssertEqual(Endpoint.courses().path, "/courses")
        XCTAssertEqual(Endpoint.categories().path, "/categories")
    }

    func test_statistic_decodes() throws {
        let items: [Statistic] = try decode(Fixtures.statisticsList)
        XCTAssertEqual(items.map(\.count), [8, 6039, 14101])
        XCTAssertEqual(items[1].title, "Всего обучающихся")
        XCTAssertEqual(items[1].id, "Всего обучающихся")
    }

    func test_course_decodes_withNullSubtitle() throws {
        let items: [Course] = try decode(Fixtures.coursesList)
        XCTAssertEqual(items[0].name, "Самообследование")
        XCTAssertNil(items[0].subtitle)
        XCTAssertEqual(items[0].image, URL(string: "https://rau.am/uploads/course/1585513619_index.jfif"))
        XCTAssertEqual(items[1].order, 2)
        XCTAssertEqual(items[1].subtitle, "Digital")
    }

    func test_category_decodes() throws {
        let items: [SiteCategory] = try decode(Fixtures.categoriesList)
        XCTAssertEqual(items.map(\.id), [1, 15])
        XCTAssertEqual(items[0].url, URL(string: "https://dic.rau.am/"))
        XCTAssertNotNil(items[1].icon)
    }

    func test_envelope_exposesSectionTitle() throws {
        let json = Fixtures.envelope(Fixtures.categoriesList, title: "Категории")
        let response: APIResponse<[SiteCategory]> = try decode(json)
        XCTAssertEqual(response.title, "Категории")
        XCTAssertEqual(response.data.count, 2)
    }

    func test_services_routeAndForwardTitle() async throws {
        let stats: [Statistic] = try decode(Fixtures.statisticsList)
        let courses: [Course] = try decode(Fixtures.coursesList)
        let categories: [SiteCategory] = try decode(Fixtures.categoriesList)
        let client = MockAPIClient { endpoint in
            switch endpoint.path {
            case "/statistics": return APIResponse(data: stats)
            case "/courses": return APIResponse(data: courses, title: "Курсы и Разделы")
            default: return APIResponse(data: categories, title: "Категории")
            }
        }
        let api = API(client: client)

        let fetchedStats = try await api.statistics.list()
        let fetchedCourses = try await api.courses.list()
        let fetchedCategories = try await api.categories.list()

        XCTAssertEqual(fetchedStats, stats)
        XCTAssertEqual(fetchedCourses, TitledList(title: "Курсы и Разделы", items: courses))
        XCTAssertEqual(fetchedCategories.title, "Категории")
        XCTAssertEqual(client.endpoints, [.statistics(), .courses(), .categories()])
    }

    func test_service_throwsWhenSuccessIsFalse() async {
        let client = MockAPIClient { _ in APIResponse(data: [Course](), success: false) }
        let error = await captureError { try await CoursesService(client: client).list() }
        XCTAssertEqual(error as? NetworkError, .unsuccessfulResponse)
    }
}
