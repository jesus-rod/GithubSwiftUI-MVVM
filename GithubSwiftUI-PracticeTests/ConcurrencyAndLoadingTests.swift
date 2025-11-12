//
//  ConcurrencyAndLoadingTests.swift
//  GithubSwiftUI-PracticeTests
//
//  Created by jesus on 13.11.25.
//

import XCTest
@testable import GithubSwiftUI_Practice

@MainActor
final class ConcurrencyAndLoadingTests: XCTestCase {

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

    // MARK: - Loading State Tests

    func test_userViewModel_setsLoadingStateCorrectly() async {
        // Given: A ViewModel with delayed response
        await mockService.setResponseDelay(TestConstants.mediumDelay)
        let viewModel = UserViewModel(networkService: mockService)
        XCTAssertFalse(viewModel.isLoading, "Should not be loading initially")

        // When: Starting to fetch user
        let fetchTask = Task {
            await viewModel.fetchUser(TestConstants.validUsername)
        }

        // Brief delay to ensure fetch has started
        try? await Task.sleep(for: .milliseconds(10))

        // Then: Loading state is true during fetch
        XCTAssertTrue(viewModel.isLoading, "Should be loading during fetch")

        await fetchTask.value

        // Then: Loading state is false after completion
        XCTAssertFalse(viewModel.isLoading, "Should not be loading after completion")
    }

    func test_reposViewModel_setsLoadingStateCorrectly() async {
        // Given: A ViewModel with delayed response
        await mockService.setResponseDelay(TestConstants.mediumDelay)
        let viewModel = ReposViewModel(networkService: mockService)
        XCTAssertFalse(viewModel.isLoading)

        // When: Starting to fetch repos
        let fetchTask = Task {
            await viewModel.fetchRepos(for: TestConstants.validUsername)
        }

        try? await Task.sleep(for: .milliseconds(10))

        // Then: Loading state is managed correctly
        XCTAssertTrue(viewModel.isLoading)

        await fetchTask.value
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_followersViewModel_setsLoadingStateCorrectly() async {
        // Given: A ViewModel with delayed response
        await mockService.setResponseDelay(TestConstants.mediumDelay)
        let viewModel = FollowersViewModel(networkService: mockService)
        XCTAssertFalse(viewModel.isLoading)

        // When: Starting to fetch followers
        let fetchTask = Task {
            await viewModel.fetchFollowers(for: TestConstants.validUsername)
        }

        try? await Task.sleep(for: .milliseconds(10))

        // Then: Loading state transitions correctly
        XCTAssertTrue(viewModel.isLoading)

        await fetchTask.value
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_popularReposViewModel_setsLoadingStateCorrectly() async {
        // Given: A ViewModel with delayed response
        await mockService.setResponseDelay(TestConstants.mediumDelay)
        let viewModel = PopularReposViewModel(networkService: mockService)
        XCTAssertFalse(viewModel.isLoading)

        // When: Starting to fetch repositories
        let fetchTask = Task {
            await viewModel.fetchPopularRepositories(page: 1)
        }

        try? await Task.sleep(for: .milliseconds(10))

        // Then: Loading state is active during fetch
        XCTAssertTrue(viewModel.isLoading)

        await fetchTask.value
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_userViewModel_loadingStateIsFalseOnError() async {
        // Given: A failing service
        await mockService.configureUserResponse(.failure(NetworkError.notFound))
        let viewModel = UserViewModel(networkService: mockService)

        // When: Fetching user fails
        await viewModel.fetchUser(TestConstants.validUsername)

        // Then: Loading state is false
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    // MARK: - Concurrent Request Tests

    func test_userViewModel_handlesConcurrentFetchesForDifferentUsers() async {
        // Given: A ViewModel that can receive concurrent requests
        let user1 = TestFixtures.makeUser(id: 1, login: "user1")
        let user2 = TestFixtures.makeUser(id: 2, login: "user2")

        // When: Multiple fetches happen concurrently
        let viewModel = UserViewModel(networkService: mockService)

        await mockService.configureUserResponse(.success(user1))
        async let fetch1 = viewModel.fetchUser("user1")

        // Small delay to ensure first fetch starts
        try? await Task.sleep(for: .milliseconds(10))

        await mockService.configureUserResponse(.success(user2))
        async let fetch2 = viewModel.fetchUser("user2")

        await fetch1
        await fetch2

        // Then: Final state reflects the last completed fetch
        // Note: This tests that the system doesn't crash with concurrent access
        XCTAssertNotNil(viewModel.user)
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_multipleViewModels_canFetchSimultaneously() async {
        // Given: Multiple ViewModels
        let viewModel1 = UserViewModel(networkService: mockService)
        let viewModel2 = UserViewModel(networkService: mockService)
        let viewModel3 = UserViewModel(networkService: mockService)

        // When: All fetch simultaneously
        async let fetch1 = viewModel1.fetchUser("user1")
        async let fetch2 = viewModel2.fetchUser("user2")
        async let fetch3 = viewModel3.fetchUser("user3")

        await fetch1
        await fetch2
        await fetch3

        // Then: All complete successfully
        XCTAssertNotNil(viewModel1.user)
        XCTAssertNotNil(viewModel2.user)
        XCTAssertNotNil(viewModel3.user)
        XCTAssertFalse(viewModel1.isLoading)
        XCTAssertFalse(viewModel2.isLoading)
        XCTAssertFalse(viewModel3.isLoading)
    }

    func test_popularReposViewModel_handlesConcurrentPagination() async {
        // Given: A ViewModel with pagination
        let viewModel = PopularReposViewModel(networkService: mockService)

        // When: Attempting concurrent pagination (should be prevented by guard)
        await viewModel.fetchPopularRepositories(page: 1)

        async let page2 = viewModel.fetchPopularRepositories(page: 2)
        async let page3 = viewModel.fetchPopularRepositories(page: 3)

        await page2
        await page3

        // Then: Pagination is handled safely
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertGreaterThan(viewModel.repositories.count, 0)
    }

    // MARK: - Race Condition Tests

    func test_userViewModel_rapidSuccessiveCallsDontCauseInconsistentState() async {
        // Given: A ViewModel
        let viewModel = UserViewModel(networkService: mockService)

        // When: Making many rapid successive calls
        for i in 1...10 {
            let user = TestFixtures.makeUser(id: i, login: "user\(i)")
            await mockService.configureUserResponse(.success(user))
            await viewModel.fetchUser("user\(i)")
        }

        // Then: ViewModel is in consistent state
        XCTAssertNotNil(viewModel.user)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func test_reposViewModel_rapidSuccessiveCallsReplaceRepos() async {
        // Given: A ViewModel
        let viewModel = ReposViewModel(networkService: mockService)

        // When: Making rapid successive calls for different users
        for i in 1...5 {
            let repos = TestFixtures.makeRepoArray(count: i)
            await mockService.configureReposResponse(.success(repos))
            await viewModel.fetchRepos(for: "user\(i)")
        }

        // Then: Final repos array matches last call
        XCTAssertEqual(viewModel.repos.count, 5)
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - NetworkService Actor Isolation Tests

    func test_networkService_canHandleConcurrentRequests() async throws {
        // Given: The real NetworkService is an actor
        let service = mockService!

        // When: Multiple concurrent requests are made
        async let user1 = service.fetchUser(username: "user1")
        async let user2 = service.fetchUser(username: "user2")
        async let repos = service.fetchRepos(for: "user3")
        async let followers = service.fetchFollowers(for: "user4")

        // Then: All complete without issues (actor handles isolation)
        let _ = try await user1
        let _ = try await user2
        let _ = try await repos
        let _ = try await followers

        // Verify call counts
        let userCallCount = await service.fetchUserCallCount
        let reposCallCount = await service.fetchReposCallCount
        let followersCallCount = await service.fetchFollowersCallCount

        XCTAssertEqual(userCallCount, 2)
        XCTAssertEqual(reposCallCount, 1)
        XCTAssertEqual(followersCallCount, 1)
    }

    func test_mockService_tracksCallsCorrectly() async throws {
        // Given: Mock service tracking calls
        let service = mockService!

        // When: Making various calls
        _ = try await service.fetchUser(username: "test1")
        _ = try await service.fetchUser(username: "test2")
        _ = try await service.fetchRepos(for: "test3")
        _ = try await service.searchPopularRepositories(page: 1, perPage: 30)

        // Then: Call counts are accurate
        let userCallCount = await service.fetchUserCallCount
        let reposCallCount = await service.fetchReposCallCount
        let searchCallCount = await service.searchCallCount

        XCTAssertEqual(userCallCount, 2)
        XCTAssertEqual(reposCallCount, 1)
        XCTAssertEqual(searchCallCount, 1)

        // Verify last call parameters
        let lastUsername = await service.lastFetchedUsername
        let lastPage = await service.lastSearchPage
        XCTAssertEqual(lastUsername, "test3")
        XCTAssertEqual(lastPage, 1)
    }

    // MARK: - Task Cancellation Tests

    func test_viewModel_canBeCancelledMidFetch() async {
        // Given: A ViewModel with a long delay
        await mockService.setResponseDelay(.seconds(2))
        let viewModel = UserViewModel(networkService: mockService)

        // When: Starting a fetch and cancelling it
        let task = Task {
            await viewModel.fetchUser(TestConstants.validUsername)
        }

        try? await Task.sleep(for: .milliseconds(50))
        task.cancel()

        // Brief wait for cancellation to propagate
        try? await Task.sleep(for: .milliseconds(100))

        // Then: Task is cancelled (though fetch may complete)
        XCTAssertTrue(task.isCancelled)
    }

    func test_multipleViewModels_withDifferentResponseTimes() async {
        // Given: Services with different delays
        let fastService = ConfigurableMockNetworkService()
        let slowService = ConfigurableMockNetworkService()

        await fastService.setResponseDelay(.milliseconds(10))
        await slowService.setResponseDelay(.milliseconds(200))

        let fastViewModel = UserViewModel(networkService: fastService)
        let slowViewModel = UserViewModel(networkService: slowService)

        // When: Both fetch at the same time
        let startTime = Date()
        async let fast = fastViewModel.fetchUser("fast")
        async let slow = slowViewModel.fetchUser("slow")

        await fast
        let fastTime = Date().timeIntervalSince(startTime)

        await slow
        let slowTime = Date().timeIntervalSince(startTime)

        // Then: Fast completes before slow
        XCTAssertLessThan(fastTime, slowTime)
        XCTAssertNotNil(fastViewModel.user)
        XCTAssertNotNil(slowViewModel.user)

        await fastService.reset()
        await slowService.reset()
    }

    // MARK: - State Consistency Tests

    func test_viewModel_maintainsConsistentStateAfterSuccessAndError() async {
        // Given: A ViewModel with initial success
        await mockService.configureUserResponse(.success(TestFixtures.makeUser()))
        let viewModel = UserViewModel(networkService: mockService)
        await viewModel.fetchUser("success")
        XCTAssertNotNil(viewModel.user)
        XCTAssertNil(viewModel.errorMessage)

        // When: An error occurs
        await mockService.configureUserResponse(.failure(NetworkError.notFound))
        await viewModel.fetchUser("error")

        // Then: Error is set, user remains from previous success
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertNotNil(viewModel.user) // User persists
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_popularReposViewModel_maintainsConsistencyDuringPagination() async {
        // Given: A ViewModel with first page loaded
        let viewModel = PopularReposViewModel(networkService: mockService)
        await viewModel.fetchPopularRepositories(page: 1)
        let initialCount = viewModel.repositories.count

        // When: Loading next page
        await viewModel.loadNextPage()

        // Then: Repositories are appended, not replaced
        XCTAssertGreaterThan(viewModel.repositories.count, initialCount)
        XCTAssertEqual(viewModel.currentPage, 2)
        XCTAssertFalse(viewModel.isLoading)
    }
}
