import Foundation
import Combine

/// Explore đọc **cùng** `HomeCatalogProviding` với Shop.
@MainActor
final class ExploreViewModel: ObservableObject {
    @Published private(set) var isLoading = false
    @Published private(set) var categories: [CategoryTree] = []
    @Published private(set) var activeEvents: [ActiveEvent] = []
    @Published var searchText = ""

    private let catalog: HomeCatalogProviding

    init(catalog: HomeCatalogProviding = HomeRepository.shared) {
        self.catalog = catalog
    }

    var filteredCategories: [CategoryTree] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return categories }
        return categories.filter { $0.name.localizedCaseInsensitiveContains(q) }
    }

    func load() async {
        apply(catalog.cachedCatalog())

        let cached = catalog.cachedCatalog()

        // Categories trống → load full catalog.
        if cached.categories.isEmpty {
            isLoading = true
            defer { isLoading = false }
            apply(await catalog.loadHomeCatalog())
        }

        // Active events có thể thiếu dù categories đã có (load cũ / hot reload).
        if catalog.cachedCatalog().activeEvents.isEmpty {
            let events = await catalog.ensureActiveEvents()
            activeEvents = events
        } else {
            activeEvents = catalog.cachedCatalog().activeEvents
        }
    }

    private func apply(_ snapshot: HomeCatalog) {
        categories = snapshot.categories
        activeEvents = snapshot.activeEvents
    }
}
