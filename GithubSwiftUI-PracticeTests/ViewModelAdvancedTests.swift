//
//  ViewModelAdvancedTests.swift
//  GithubSwiftUI-PracticeTests
//
//  Created by jesus on 13.11.25.
//

import XCTest
@testable import GithubSwiftUI_Practice

@MainActor
final class ViewModelAdvancedTests: XCTestCase {

    var mockService: ConfigurableMockNetworkService!

    override func setUp() async throws {
        try await super.setUp()
        mockService = ConfigurableMockNetworkService()
    }

    override func tearDown() async throws {
        await mockService.reset()
        mockService = nil
        try await super.tearDown()
    }

    // MARK: - UserViewModel Tests

    func test_userViewModel_clearError_removesErrorMessage() async {
        // Given: A ViewModel with an error
        await mockService.configureUserResponse(.failure(NetworkError.notFound))
        let viewModel = UserViewModel(networkService: mockService)
        await viewModel.fetchUser(TestConstants.validUsername)
        XCTAssertNotNil(viewModel.errorMessage)

        // When: Clearing the error
        viewModel.clearError()

        // Then: Error message is removed
        XCTAssertNil(viewModel.errorMessage)
    }

    func test_userViewModel_handlesEmptyUsername() async {
        // Given: A ViewModel
        let viewModel = UserViewModel(networkService: mockService)

        // When: Fetching with empty username
        await viewModel.fetchUser(TestConstants.emptyUsername)

        // Then: User is fetched (API handles empty username)
        let callCount = await mockService.fetchUserCallCount
        XCTAssertEqual(callCount, 1)
    }

    func test_userViewModel_handlesSpecialCharactersInUsername() async {
        // Given: A ViewModel
        let viewModel = UserViewModel(networkService: mockService)

        // When: Fetching with special characters
        await viewModel.fetchUser(TestConstants.specialCharUsername)

        // Then: Request is made successfully
        let username = await mockService.lastFetchedUsername
        XCTAssertEqual(username, TestConstants.specialCharUsername)
    }

    func test_userViewModel_handlesUnicodeUsername() async {
        // Given: A ViewModel
        let viewModel = UserViewModel(networkService: mockService)

        // When: Fetching with unicode characters
        await viewModel.fetchUser(TestConstants.unicodeUsername)

        // Then: Request is made successfully
        let username = await mockService.lastFetchedUsername
        XCTAssertEqual(username, TestConstants.unicodeUsername)
    }

    func test_userViewModel_handlesLongUsername() async {
        // Given: A ViewModel
        let viewModel = UserViewModel(networkService: mockService)

        // When: Fetching with very long username
        await viewModel.fetchUser(TestConstants.longUsername)

        // Then: Request is made (API will handle validation)
        let callCount = await mockService.fetchUserCallCount
        XCTAssertEqual(callCount, 1)
    }

    func test_userViewModel_handlesNetworkError() async {
        // Given: A failing network service
        await mockService.simulateNetworkError()
        let viewModel = UserViewModel(networkService: mockService)

        // When: Fetching user
        await viewModel.fetchUser(TestConstants.validUsername)

        // Then: Error message contains network error details
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.user)
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_userViewModel_handlesNotFoundError() async {
        // Given: A service returning not found
        await mockService.simulateNotFoundError()
        let viewModel = UserViewModel(networkService: mockService)

        // When: Fetching user
        await viewModel.fetchUser(TestConstants.validUsername)

        // Then: Appropriate error message is set
        XCTAssertEqual(viewModel.errorMessage, NetworkError.notFound.errorMessage)
        XCTAssertNil(viewModel.user)
    }

    func test_userViewModel_handlesRateLimitError() async {
        // Given: A service returning rate limit error
        await mockService.simulateRateLimitError()
        let viewModel = UserViewModel(networkService: mockService)

        // When: Fetching user
        await viewModel.fetchUser(TestConstants.validUsername)

        // Then: Rate limit error message is shown
        XCTAssertEqual(viewModel.errorMessage, NetworkError.rateLimitExceeded.errorMessage)
        XCTAssertNil(viewModel.user)
    }

    func test_userViewModel_consecutiveFetchesUpdateUser() async {
        // Given: A ViewModel that fetches successfully
        let user1 = TestFixtures.makeUser(id: 1, login: "user1")
        let user2 = TestFixtures.makeUser(id: 2, login: "user2")
        let viewModel = UserViewModel(networkService: mockService)

        // When: Fetching multiple times with different results
        await mockService.configureUserResponse(.success(user1))
        await viewModel.fetchUser("user1")
        XCTAssertEqual(viewModel.user?.login, "user1")

        await mockService.configureUserResponse(.success(user2))
        await viewModel.fetchUser("user2")

        // Then: User is updated
        XCTAssertEqual(viewModel.user?.login, "user2")
        XCTAssertEqual(viewModel.user?.id, 2)
    }

    func test_userViewModel_errorIsClearedOnSuccessfulFetch() async {
        // Given: A ViewModel with an existing error
        await mockService.configureUserResponse(.failure(NetworkError.notFound))
        let viewModel = UserViewModel(networkService: mockService)
        await viewModel.fetchUser("fail")
        XCTAssertNotNil(viewModel.errorMessage)

        // When: A successful fetch occurs
        await mockService.configureUserResponse(.success(TestFixtures.makeUser()))
        await viewModel.fetchUser("success")

        // Then: Error is cleared
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertNotNil(viewModel.user)
    }

    // MARK: - ReposViewModel Tests

    func test_reposViewModel_handlesEmptyRepositoryList() async {
        // Given: A service returning empty repos
        await mockService.configureEmptyResults()
        let viewModel = ReposViewModel(networkService: mockService)

        // When: Fetching repos
        await viewModel.fetchRepos(for: TestConstants.validUsername)

        // Then: Repos array is empty but no error
        XCTAssertTrue(viewModel.repos.isEmpty)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_reposViewModel_handlesLargeNumberOfRepos() async {
        // Given: A service returning many repos
        let manyRepos = TestFixtures.makeRepoArray(count: 100)
        await mockService.configureReposResponse(.success(manyRepos))
        let viewModel = ReposViewModel(networkService: mockService)

        // When: Fetching repos
        await viewModel.fetchRepos(for: TestConstants.validUsername)

        // Then: All repos are loaded
        XCTAssertEqual(viewModel.repos.count, 100)
        XCTAssertNil(viewModel.errorMessage)
    }

    func test_reposViewModel_replacesReposOnNewFetch() async {
        // Given: A ViewModel with existing repos
        let initialRepos = TestFixtures.makeRepoArray(count: 2)
        await mockService.configureReposResponse(.success(initialRepos))
        let viewModel = ReposViewModel(networkService: mockService)
        await viewModel.fetchRepos(for: "user1")
        XCTAssertEqual(viewModel.repos.count, 2)

        // When: Fetching repos for a different user
        let newRepos = TestFixtures.makeRepoArray(count: 5)
        await mockService.configureReposResponse(.success(newRepos))
        await viewModel.fetchRepos(for: "user2")

        // Then: Repos are replaced
        XCTAssertEqual(viewModel.repos.count, 5)
    }

    // MARK: - FollowersViewModel Tests

    func test_followersViewModel_handlesEmptyFollowersList() async {
        // Given: A service returning empty followers
        await mockService.configureEmptyResults()
        let viewModel = FollowersViewModel(networkService: mockService)

        // When: Fetching followers
        await viewModel.fetchFollowers(for: TestConstants.validUsername)

        // Then: Followers array is empty but no error
        XCTAssertTrue(viewModel.followers.isEmpty)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_followersViewModel_handlesLargeNumberOfFollowers() async {
        // Given: A service returning many followers
        let manyFollowers = TestFixtures.makeUserArray(count: 200)
        await mockService.configureFollowersResponse(.success(manyFollowers))
        let viewModel = FollowersViewModel(networkService: mockService)

        // When: Fetching followers
        await viewModel.fetchFollowers(for: TestConstants.validUsername)

        // Then: All followers are loaded
        XCTAssertEqual(viewModel.followers.count, 200)
        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - PopularReposViewModel Tests

    func test_popularReposViewModel_handlesEmptySearchResults() async {
        // Given: A service returning empty results
        await mockService.configureSearchResponse(.success(
            SearchResponse(totalCount: 0, incompleteResults: false, items: [])
        ))
        let viewModel = PopularReposViewModel(networkService: mockService)

        // When: Fetching popular repositories
        await viewModel.fetchPopularRepositories(page: 1)

        // Then: Repositories are empty and no more pages
        XCTAssertTrue(viewModel.repositories.isEmpty)
        XCTAssertFalse(viewModel.hasMorePages)
        XCTAssertEqual(viewModel.totalCount, 0)
        XCTAssertNil(viewModel.errorMessage)
    }

    func test_popularReposViewModel_preventsLoadingWhenAlreadyLoading() async {
        // Given: A ViewModel with a delayed response
        await mockService.setResponseDelay(TestConstants.mediumDelay)
        let viewModel = PopularReposViewModel(networkService: mockService)

        // When: Multiple fetch calls are made rapidly
        let task1 = Task { await viewModel.fetchPopularRepositories(page: 1) }
        let task2 = Task { await viewModel.fetchPopularRepositories(page: 1) }

        await task1.value
        await task2.value

        // Then: Only one request was made
        let callCount = await mockService.searchCallCount
        XCTAssertEqual(callCount, 1)
    }

    func test_popularReposViewModel_preventsLoadNextPageWhenAlreadyLoading() async {
        // Given: A ViewModel with a delayed response
        await mockService.setResponseDelay(TestConstants.mediumDelay)
        let viewModel = PopularReposViewModel(networkService: mockService)
        await viewModel.fetchPopularRepositories(page: 1)

        // When: Multiple loadNextPage calls are made while loading
        let task1 = Task { await viewModel.loadNextPage() }
        let task2 = Task { await viewModel.loadNextPage() }

        await task1.value
        await task2.value

        // Then: Only appropriate number of requests made
        let callCount = await mockService.searchCallCount
        XCTAssertLessThanOrEqual(callCount, 2)
    }

    func test_popularReposViewModel_calculatesHasMorePagesCorrectly() async {
        // Given: A response with limited items
        await mockService.configureSearchResponse(.success(
            SearchResponse(totalCount: 10, incompleteResults: false, items: TestFixtures.makeRepoArray(count: 10))
        ))
        let viewModel = PopularReposViewModel(networkService: mockService)

        // When: Fetching all available items
        await viewModel.fetchPopularRepositories(page: 1)

        // Then: hasMorePages is false when all items fetched
        XCTAssertFalse(viewModel.hasMorePages)
        XCTAssertEqual(viewModel.repositories.count, 10)
        XCTAssertEqual(viewModel.totalCount, 10)
    }

    func test_popularReposViewModel_refreshClearsExistingData() async {
        // Given: A ViewModel with multiple pages loaded
        let viewModel = PopularReposViewModel(networkService: mockService)
        await viewModel.fetchPopularRepositories(page: 1)
        await viewModel.fetchPopularRepositories(page: 2)
        let countBeforeRefresh = viewModel.repositories.count

        // When: Refreshing
        await viewModel.refresh()

        // Then: Data is reset to first page only
        XCTAssertLessThan(viewModel.repositories.count, countBeforeRefresh)
        XCTAssertEqual(viewModel.currentPage, 1)
        XCTAssertTrue(viewModel.hasMorePages)
    }

    func test_popularReposViewModel_handlesIncompleteResults() async {
        // Given: A response with incomplete results flag
        await mockService.configureSearchResponse(.success(
            SearchResponse(totalCount: 1000, incompleteResults: true, items: TestFixtures.makeRepoArray(count: 30))
        ))
        let viewModel = PopularReposViewModel(networkService: mockService)

        // When: Fetching repositories
        await viewModel.fetchPopularRepositories(page: 1)

        // Then: Results are still displayed
        XCTAssertEqual(viewModel.repositories.count, 30)
        XCTAssertTrue(viewModel.hasMorePages)
    }

    // MARK: - Edge Case Tests

    func test_viewModel_handlesUnexpectedErrorType() async {
        // Given: A service throwing a non-NetworkError
        struct CustomError: Error {}
        await mockService.configureUserResponse(.failure(CustomError()))
        let viewModel = UserViewModel(networkService: mockService)

        // When: Fetching user
        await viewModel.fetchUser(TestConstants.validUsername)

        // Then: Generic error message is shown
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, "An unexpected error ocurred")
    }

    func test_viewModel_handlesNilOptionalFields() async {
        // Given: A user with all optional fields nil
        let minimalUser = TestFixtures.makeMinimalUser()
        await mockService.configureUserResponse(.success(minimalUser))
        let viewModel = UserViewModel(networkService: mockService)

        // When: Fetching user
        await viewModel.fetchUser("minimal")

        // Then: User is set despite missing optional fields
        XCTAssertNotNil(viewModel.user)
        XCTAssertNil(viewModel.user?.bio)
        XCTAssertNil(viewModel.user?.name)
        XCTAssertNil(viewModel.user?.publicRepos)
    }
}
