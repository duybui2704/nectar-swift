import SwiftUI

struct ExploreView: View {
    @StateObject private var viewModel = ExploreViewModel()
    @FocusState private var searchFocused: Bool
    @HotReloadObserver private var _hr

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: NectarMetrics.spacing.md) {
                    searchField
                    ActiveEventsBanner(events: viewModel.activeEvents)
                  
                    ExploreCategoryGrid(categories: viewModel.filteredCategories)
                }
                .screenPadding()
                .padding(.top, NectarMetrics.spacing.sm)
                .padding(.bottom, 100)
            }
            .hidesTabBarOnScroll()
            .background(NectarColors.background.ignoresSafeArea())
            .navigationTitle("Find Products")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.load()
            }
            .hotReload()
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(NectarColors.textSecondary)
            TextField(
                "Search Store",
                text: $viewModel.searchText,
                prompt: Text("Search Store").foregroundStyle(NectarColors.textSecondary)
            )
            .focused($searchFocused)
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
        }
        .padding(.horizontal, 14)
        .frame(height: NectarMetrics.button.inputHeight)
        .background(Color(.systemGray6))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(searchFocused ? NectarColors.green : .secondary, lineWidth: 1.5)
        )
        .cornerRadius(8)

    }
}
