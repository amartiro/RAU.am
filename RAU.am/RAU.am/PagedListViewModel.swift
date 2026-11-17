import Foundation
import NetworkLayer

/// Generic infinite-scroll list: loads page after page using the server's `meta.has_more`.
@MainActor
final class PagedListViewModel<Item: Identifiable>: ObservableObject {
    typealias Fetch = (API, Int, Int) async throws -> Paginated<Item>

    @Published private(set) var items: [Item] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var hasMore = true

    private var nextPage = 1
    private var token = UUID()              // lets a reload invalidate in-flight requests
    private let perPage: Int
    private let fetch: Fetch

    init(perPage: Int, fetch: @escaping Fetch) {
        self.perPage = perPage
        self.fetch = fetch
    }

    func reload(api: API) async {
        token = UUID()
        items = []
        nextPage = 1
        hasMore = true
        errorMessage = nil
        isLoading = false
        await loadMore(api: api)
    }

    func loadMore(api: API) async {
        guard !isLoading, hasMore else { return }
        let myToken = token
        isLoading = true
        errorMessage = nil
        do {
            let result = try await fetch(api, nextPage, perPage)
            guard myToken == token else { return }
            items.append(contentsOf: result.items)
            hasMore = result.meta?.hasMore ?? (result.items.count == perPage)
            nextPage += 1
            isLoading = false
        } catch {
            guard myToken == token else { return }
            isLoading = false
            if let networkError = error as? NetworkError, networkError == .cancelled { return }
            errorMessage = error.localizedDescription
        }
    }

    /// Call from each row's `.task`: loads the next page when the user is near the end.
    func loadMoreIfNeeded(current item: Item, api: API) async {
        guard let index = items.firstIndex(where: { $0.id == item.id }),
              index >= items.count - 3 else { return }
        await loadMore(api: api)
    }
}
