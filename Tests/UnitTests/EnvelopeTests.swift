import XCTest
import TestSupport
@testable import NetworkLayer

final class EnvelopeTests: XCTestCase {

    func test_realInstitutesResponse_decodes() throws {
        let response = try JSONDecoder.api().decode(APIResponse<[Institute]>.self,
                                                    from: Fixtures.data(Fixtures.realInstitutesResponse))
        XCTAssertTrue(response.success)
        XCTAssertEqual(response.lang, APILanguage(id: 2, code: "en"))
        XCTAssertNil(response.meta)
        XCTAssertEqual(response.data.map(\.id), [4, 7, 1, 6, 2, 3, 5, 8, 11])
        XCTAssertEqual(response.data[0].slug, "ibmp")
    }

    func test_metaBlock_decodes() throws {
        let json = Fixtures.envelope(Fixtures.newsList, meta: Fixtures.newsMeta)
        let response = try JSONDecoder.api().decode(APIResponse<[News]>.self, from: Fixtures.data(json))
        XCTAssertEqual(response.meta, PageMeta(page: 1, perPage: 10, total: 351, lastPage: 36, hasMore: true))
    }

    func test_missingSuccessAndLang_areTolerated() throws {
        let response = try JSONDecoder.api().decode(APIResponse<[Page]>.self, from: Fixtures.data(#"{"data": []}"#))
        XCTAssertTrue(response.success)
        XCTAssertNil(response.lang)
        XCTAssertNil(response.meta)
    }

    func test_missingData_isADecodingError() {
        XCTAssertThrowsError(try JSONDecoder.api().decode(APIResponse<[Page]>.self,
                                                          from: Fixtures.data(#"{"success": true}"#)))
    }

    func test_paginated_hasMoreComesFromMeta() {
        let more = Paginated(items: [1], meta: PageMeta(page: 1, perPage: 1, total: 5, lastPage: 5, hasMore: true))
        let last = Paginated(items: [1], meta: PageMeta(page: 5, perPage: 1, total: 5, lastPage: 5, hasMore: false))
        let unknown = Paginated(items: [1], meta: nil)
        XCTAssertTrue(more.hasMore)
        XCTAssertFalse(last.hasMore)
        XCTAssertFalse(unknown.hasMore)
    }

    func test_service_throwsWhenSuccessIsFalse() async {
        let client = MockAPIClient { _ in APIResponse(data: [Institute](), success: false) }
        let error = await captureError { try await InstitutesService(client: client).list() }
        XCTAssertEqual(error as? NetworkError, .unsuccessfulResponse)
    }

    func test_fullStack_realInstitutesResponse_overMockedHTTP() async throws {
        let http = MockHTTPClient.responding(json: Fixtures.realInstitutesResponse)
        let api = API(client: APIClient(baseURL: URL(string: "https://api.example.com")!, http: http))

        let institutes = try await api.institutes.list()

        XCTAssertEqual(institutes.count, 9)
        XCTAssertEqual(institutes.last?.slug, "iphilology")
    }
}
