//
//  GithubSwiftUI_PracticeTests.swift
//  GithubSwiftUI-PracticeTests
//
//  Created by jesus on 08.11.25.
//

import XCTest
@testable import GithubSwiftUI_Practice

@MainActor
final class GithubSwiftUI_PracticeTests: XCTestCase {
    
    func test_viewModelFetchesUserSuccessfully() async {
        let mockNetworkService = MockNetworkService()
        let viewModel = UserViewModel(networkService: mockNetworkService)
        
        await viewModel.fetchUser("test-user")
        XCTAssertNotNil(viewModel.user)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func test_viewModelFetchesUserFailure() async {
        let mockNetworkService = MockNetworkService()
        await mockNetworkService.setShouldFail(true)
        let viewModel = UserViewModel(networkService: mockNetworkService)
        
        await viewModel.fetchUser("test-user")
        XCTAssertNil(viewModel.user)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func test_viewModelFetchesReposSuccessfully() async {
        let mockNetworkService = MockNetworkService()
        let viewModel = ReposViewModel(networkService: mockNetworkService)
        await viewModel.fetchRepos(for: "test-user")
        XCTAssertNotNil(viewModel.repos)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func test_viewModelFetchesReposFailure() async {
        let mockNetworkService = MockNetworkService()
        await mockNetworkService.setShouldFail(true)
        let viewModel = ReposViewModel(networkService: mockNetworkService)
        await viewModel.fetchRepos(for: "test-user")
        XCTAssertEqual(viewModel.repos.count, 0)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func test_viewModelFetchesFollowersSuccessfully() async {
        let mockNetworkService = MockNetworkService()
        let viewModel = FollowersViewModel(networkService: mockNetworkService)
        
        await viewModel.fetchFollowers(for: "test-user")
        XCTAssertEqual(viewModel.followers.count, 2)
        XCTAssertEqual(viewModel.followers[0].login, "follower1")
        XCTAssertEqual(viewModel.followers[1].login, "follower2")
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func test_viewModelFetchesFollowersFailure() async {
        let mockNetworkService = MockNetworkService()
        await mockNetworkService.setShouldFail(true)
        let viewModel = FollowersViewModel(networkService: mockNetworkService)

        await viewModel.fetchFollowers(for: "test-user")
        XCTAssertTrue(viewModel.followers.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - PopularReposViewModel Tests

    func test_popularReposViewModel_fetchesSuccessfully() async {
        let mockNetworkService = MockNetworkService()
        let viewModel = PopularReposViewModel(networkService: mockNetworkService)

        await viewModel.fetchPopularRepositories(page: 1)

        XCTAssertEqual(viewModel.repositories.count, 3)
        XCTAssertEqual(viewModel.currentPage, 1)
        XCTAssertEqual(viewModel.totalCount, 100)
        XCTAssertTrue(viewModel.hasMorePages)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_popularReposViewModel_fetchesFailure() async {
        let mockNetworkService = MockNetworkService()
        await mockNetworkService.setShouldFail(true)
        let viewModel = PopularReposViewModel(networkService: mockNetworkService)

        await viewModel.fetchPopularRepositories(page: 1)

        XCTAssertTrue(viewModel.repositories.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_popularReposViewModel_paginationAppendsResults() async {
        let mockNetworkService = MockNetworkService()
        let viewModel = PopularReposViewModel(networkService: mockNetworkService)

        // Fetch page 1
        await viewModel.fetchPopularRepositories(page: 1)
        XCTAssertEqual(viewModel.repositories.count, 3)
        XCTAssertEqual(viewModel.currentPage, 1)

        // Fetch page 2
        await viewModel.fetchPopularRepositories(page: 2)
        XCTAssertEqual(viewModel.repositories.count, 6) // 3 from page 1 + 3 from page 2
        XCTAssertEqual(viewModel.currentPage, 2)
    }

    func test_popularReposViewModel_loadNextPage() async {
        let mockNetworkService = MockNetworkService()
        let viewModel = PopularReposViewModel(networkService: mockNetworkService)

        // Initial fetch
        await viewModel.fetchPopularRepositories(page: 1)
        XCTAssertEqual(viewModel.currentPage, 1)

        // Load next page
        await viewModel.loadNextPage()
        XCTAssertEqual(viewModel.currentPage, 2)
        XCTAssertEqual(viewModel.repositories.count, 6)
    }

    func test_popularReposViewModel_doesNotLoadWhenNoMorePages() async {
        let mockNetworkService = MockNetworkService()
        let viewModel = PopularReposViewModel(networkService: mockNetworkService)

        // Manually set hasMorePages to false
        viewModel.hasMorePages = false
        let initialCount = viewModel.repositories.count

        await viewModel.loadNextPage()

        // Should not have loaded more
        XCTAssertEqual(viewModel.repositories.count, initialCount)
    }

    func test_popularReposViewModel_refresh() async {
        let mockNetworkService = MockNetworkService()
        let viewModel = PopularReposViewModel(networkService: mockNetworkService)

        // Initial fetch
        await viewModel.fetchPopularRepositories(page: 1)
        await viewModel.fetchPopularRepositories(page: 2)
        XCTAssertEqual(viewModel.repositories.count, 6)
        XCTAssertEqual(viewModel.currentPage, 2)

        // Refresh
        await viewModel.refresh()

        XCTAssertEqual(viewModel.repositories.count, 3) // Reset to page 1 only
        XCTAssertEqual(viewModel.currentPage, 1)
        XCTAssertTrue(viewModel.hasMorePages)
    }
}
