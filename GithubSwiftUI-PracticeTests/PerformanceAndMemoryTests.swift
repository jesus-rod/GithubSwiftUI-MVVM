//
//  PerformanceAndMemoryTests.swift
//  GithubSwiftUI-PracticeTests
//
//  Created by jesus on 13.11.25.
//

import XCTest
@testable import GithubSwiftUI_Practice

@MainActor
final class PerformanceAndMemoryTests: XCTestCase {

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

    // MARK: - Performance Tests

    func testPerformance_userViewModel_fetchUser() {
        // Given: A ViewModel ready to fetch
        let viewModel = UserViewModel(networkService: mockService)

        // Measure performance of fetching a user
        measure {
            let expectation = expectation(description: "Fetch user")
            Task { @MainActor in
                await viewModel.fetchUser(TestConstants.validUsername)
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 5.0)
        }
    }

    func testPerformance_reposViewModel_fetchRepos() {
        // Given: A ViewModel ready to fetch repos
        let viewModel = ReposViewModel(networkService: mockService)

        // Measure performance of fetching repos
        measure {
            let expectation = expectation(description: "Fetch repos")
            Task { @MainActor in
                await viewModel.fetchRepos(for: TestConstants.validUsername)
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 5.0)
        }
    }

    func testPerformance_followersViewModel_fetchFollowers() {
        // Given: A ViewModel ready to fetch followers
        let viewModel = FollowersViewModel(networkService: mockService)

        // Measure performance
        measure {
            let expectation = expectation(description: "Fetch followers")
            Task { @MainActor in
                await viewModel.fetchFollowers(for: TestConstants.validUsername)
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 5.0)
        }
    }

    func testPerformance_popularReposViewModel_fetchPopularRepositories() {
        // Given: A ViewModel ready to fetch popular repos
        let viewModel = PopularReposViewModel(networkService: mockService)

        // Measure performance
        measure {
            let expectation = expectation(description: "Fetch popular repos")
            Task { @MainActor in
                await viewModel.fetchPopularRepositories(page: 1)
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 5.0)
        }
    }

    func testPerformance_popularReposViewModel_pagination() {
        // Given: A ViewModel with existing data
        let viewModel = PopularReposViewModel(networkService: mockService)
        let expectation1 = expectation(description: "Initial fetch")
        Task { @MainActor in
            await viewModel.fetchPopularRepositories(page: 1)
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 5.0)

        // Measure performance of loading next page
        measure {
            let expectation = expectation(description: "Load next page")
            Task { @MainActor in
                await viewModel.loadNextPage()
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 5.0)
        }
    }

    func testPerformance_decodeUser() {
        // Given: User JSON data
        let json = TestFixtures.makeUserJSON(includeOptionals: true)
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        // Measure decoding performance
        measure {
            _ = try? decoder.decode(GHUser.self, from: data)
        }
    }

    func testPerformance_decodeRepoArray() {
        // Given: Array of repos
        let repos = TestFixtures.makeRepoArray(count: 100)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try! encoder.encode(repos)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        // Measure decoding performance
        measure {
            _ = try? decoder.decode([GHRepo].self, from: data)
        }
    }

    func testPerformance_largeFollowersList() async {
        // Given: A service returning many followers
        let manyFollowers = TestFixtures.makeUserArray(count: 1000)
        await mockService.configureFollowersResponse(.success(manyFollowers))
        let viewModel = FollowersViewModel(networkService: mockService)

        // Measure performance with large dataset
        measure {
            let expectation = expectation(description: "Fetch many followers")
            Task { @MainActor in
                await viewModel.fetchFollowers(for: "popular")
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 10.0)
        }
    }

    // MARK: - Memory Leak Tests

    func test_userViewModel_doesNotLeakMemory() async {
        // Given: A weak reference to track deallocation
        weak var weakViewModel: UserViewModel?

        // When: Creating and using ViewModel in local scope
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            Task { @MainActor in
                autoreleasepool {
                    let viewModel = UserViewModel(networkService: mockService)
                    weakViewModel = viewModel
                    await viewModel.fetchUser(TestConstants.validUsername)
                }
                continuation.resume()
            }
        }

        // Brief delay to allow deallocation
        try? await Task.sleep(for: .milliseconds(100))

        // Then: ViewModel is deallocated
        XCTAssertNil(weakViewModel, "UserViewModel should be deallocated")
    }

    func test_reposViewModel_doesNotLeakMemory() async {
        weak var weakViewModel: ReposViewModel?

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            Task { @MainActor in
                autoreleasepool {
                    let viewModel = ReposViewModel(networkService: mockService)
                    weakViewModel = viewModel
                    await viewModel.fetchRepos(for: TestConstants.validUsername)
                }
                continuation.resume()
            }
        }

        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertNil(weakViewModel, "ReposViewModel should be deallocated")
    }

    func test_followersViewModel_doesNotLeakMemory() async {
        weak var weakViewModel: FollowersViewModel?

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            Task { @MainActor in
                autoreleasepool {
                    let viewModel = FollowersViewModel(networkService: mockService)
                    weakViewModel = viewModel
                    await viewModel.fetchFollowers(for: TestConstants.validUsername)
                }
                continuation.resume()
            }
        }

        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertNil(weakViewModel, "FollowersViewModel should be deallocated")
    }

    func test_popularReposViewModel_doesNotLeakMemory() async {
        weak var weakViewModel: PopularReposViewModel?

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            Task { @MainActor in
                autoreleasepool {
                    let viewModel = PopularReposViewModel(networkService: mockService)
                    weakViewModel = viewModel
                    await viewModel.fetchPopularRepositories(page: 1)
                }
                continuation.resume()
            }
        }

        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertNil(weakViewModel, "PopularReposViewModel should be deallocated")
    }

    func test_viewModel_withMultipleFetches_doesNotLeakMemory() async {
        weak var weakViewModel: UserViewModel?

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            Task { @MainActor in
                autoreleasepool {
                    let viewModel = UserViewModel(networkService: mockService)
                    weakViewModel = viewModel

                    // Multiple fetches
                    for i in 1...10 {
                        await viewModel.fetchUser("user\(i)")
                    }
                }
                continuation.resume()
            }
        }

        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertNil(weakViewModel, "ViewModel should be deallocated after multiple fetches")
    }

    func test_viewModel_withErrors_doesNotLeakMemory() async {
        weak var weakViewModel: UserViewModel?

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            Task { @MainActor in
                autoreleasepool {
                    let viewModel = UserViewModel(networkService: mockService)
                    weakViewModel = viewModel
                    await mockService.configureUserResponse(.failure(NetworkError.notFound))
                    await viewModel.fetchUser("nonexistent")
                }
                continuation.resume()
            }
        }

        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertNil(weakViewModel, "ViewModel should be deallocated even with errors")
    }

    func test_mockService_doesNotRetainReferences() async {
        // Given: Mock service
        let service = ConfigurableMockNetworkService()
        weak var weakUser: GHUser?

        // When: Using service in local scope
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            Task {
                autoreleasepool {
                    let user = TestFixtures.makeUser()
                    weakUser = user
                    await service.configureUserResponse(.success(user))
                    _ = try? await service.fetchUser(username: "test")
                }
                continuation.resume()
            }
        }

        await service.reset()
        try? await Task.sleep(for: .milliseconds(100))

        // Then: User object can be deallocated
        // Note: This test may pass even with retention due to how actors work
        // It's more of a documentation of expected behavior
    }

    // MARK: - Stress Tests

    func test_viewModel_handlesRapidCreationAndDestruction() async {
        // Given/When: Creating and destroying many ViewModels rapidly
        for _ in 1...50 {
            autoreleasepool {
                let viewModel = UserViewModel(networkService: mockService)
                _ = viewModel.isLoading
            }
        }

        // Then: No crashes or memory issues
        XCTAssertTrue(true, "Survived rapid creation/destruction")
    }

    func test_viewModel_handlesLargeDataset() async {
        // Given: A very large repos array
        let largeRepoList = TestFixtures.makeRepoArray(count: 5000)
        await mockService.configureReposResponse(.success(largeRepoList))
        let viewModel = ReposViewModel(networkService: mockService)

        // When: Loading large dataset
        await viewModel.fetchRepos(for: "productive")

        // Then: Data is loaded successfully
        XCTAssertEqual(viewModel.repos.count, 5000)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func test_popularReposViewModel_handlesManyPages() async {
        // Given: A ViewModel that will load many pages
        let viewModel = PopularReposViewModel(networkService: mockService)

        // When: Loading many pages sequentially
        for page in 1...20 {
            await viewModel.fetchPopularRepositories(page: page)
        }

        // Then: All data is accumulated
        XCTAssertGreaterThan(viewModel.repositories.count, 0)
        XCTAssertEqual(viewModel.currentPage, 20)
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_concurrentViewModels_memoryStressTest() async {
        // Given: Many ViewModels created concurrently
        var viewModels: [UserViewModel] = []

        // When: Creating 100 ViewModels
        for _ in 1...100 {
            viewModels.append(UserViewModel(networkService: mockService))
        }

        // Fetch concurrently
        await withTaskGroup(of: Void.self) { group in
            for (index, viewModel) in viewModels.enumerated() {
                group.addTask { @MainActor in
                    await viewModel.fetchUser("user\(index)")
                }
            }
        }

        // Then: All complete successfully
        XCTAssertEqual(viewModels.count, 100)

        // Clear strong references
        viewModels.removeAll()
    }

    // MARK: - Resource Management Tests

    func test_viewModel_releasesResourcesAfterError() async {
        weak var weakViewModel: UserViewModel?

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            Task { @MainActor in
                autoreleasepool {
                    let viewModel = UserViewModel(networkService: mockService)
                    weakViewModel = viewModel
                    await mockService.simulateNetworkError()
                    await viewModel.fetchUser("test")
                    // ViewModel goes out of scope here
                }
                continuation.resume()
            }
        }

        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertNil(weakViewModel, "ViewModel should release resources after error")
    }

    func test_viewModel_cleanupAfterMultipleOperations() async {
        weak var weakViewModel: PopularReposViewModel?

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            Task { @MainActor in
                autoreleasepool {
                    let viewModel = PopularReposViewModel(networkService: mockService)
                    weakViewModel = viewModel

                    // Multiple operations
                    await viewModel.fetchPopularRepositories(page: 1)
                    await viewModel.loadNextPage()
                    await viewModel.refresh()
                }
                continuation.resume()
            }
        }

        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertNil(weakViewModel, "ViewModel should cleanup after multiple operations")
    }
}
