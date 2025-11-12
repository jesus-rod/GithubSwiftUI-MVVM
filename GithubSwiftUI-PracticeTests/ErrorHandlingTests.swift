//
//  ErrorHandlingTests.swift
//  GithubSwiftUI-PracticeTests
//
//  Created by jesus on 13.11.25.
//

import XCTest
@testable import GithubSwiftUI_Practice

@MainActor
final class ErrorHandlingTests: XCTestCase {

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

    // MARK: - NetworkError Message Tests

    func test_networkError_allCasesHaveNonEmptyMessages() {
        // Given: All NetworkError cases
        let errors: [NetworkError] = [
            .invalidURL,
            .invalidResponse,
            .invalidData,
            .notFound,
            .forbidden,
            .rateLimitExceeded,
            .networkError(NSError(domain: "test", code: 1))
        ]

        // Then: All have non-empty error messages
        for error in errors {
            XCTAssertFalse(error.errorMessage.isEmpty, "Error \(error) has empty message")
            XCTAssertGreaterThan(error.errorMessage.count, 5, "Error message too short")
        }
    }

    func test_networkError_messagesAreUserFriendly() {
        // Given: User-facing errors
        let notFound = NetworkError.notFound
        let forbidden = NetworkError.forbidden
        let rateLimit = NetworkError.rateLimitExceeded

        // Then: Messages are descriptive and user-friendly
        XCTAssertTrue(notFound.errorMessage.contains("not found"), "Should mention not found")
        XCTAssertTrue(forbidden.errorMessage.contains("forbidden") || forbidden.errorMessage.contains("Access"), "Should mention access restriction")
        XCTAssertTrue(rateLimit.errorMessage.contains("rate limit") || rateLimit.errorMessage.contains("Try again"), "Should mention rate limiting")
    }

    func test_networkError_wrapsUnderlyingErrorMessage() {
        // Given: An underlying error with custom message
        let underlyingError = NSError(
            domain: "TestDomain",
            code: 42,
            userInfo: [NSLocalizedDescriptionKey: "Custom error message"]
        )
        let networkError = NetworkError.networkError(underlyingError)

        // Then: Error message includes underlying error description
        XCTAssertEqual(networkError.errorMessage, "Custom error message")
    }

    // MARK: - ViewModel Error Handling Tests

    func test_userViewModel_convertsNetworkErrorToMessage() async {
        // Given: All NetworkError types
        let errorTypes: [NetworkError] = [
            .invalidURL,
            .invalidResponse,
            .invalidData,
            .notFound,
            .forbidden,
            .rateLimitExceeded
        ]

        let viewModel = UserViewModel(networkService: mockService)

        // When/Then: Each error type is handled
        for errorType in errorTypes {
            await mockService.configureUserResponse(.failure(errorType))
            await viewModel.fetchUser("test")

            XCTAssertNotNil(viewModel.errorMessage, "Should have error message for \(errorType)")
            XCTAssertEqual(viewModel.errorMessage, errorType.errorMessage)
            XCTAssertNil(viewModel.user)
            XCTAssertFalse(viewModel.isLoading)
        }
    }

    func test_reposViewModel_convertsNetworkErrorToMessage() async {
        // Given: Network error
        await mockService.configureReposResponse(.failure(NetworkError.notFound))
        let viewModel = ReposViewModel(networkService: mockService)

        // When: Fetching repos fails
        await viewModel.fetchRepos(for: "test")

        // Then: Error message matches NetworkError
        XCTAssertEqual(viewModel.errorMessage, NetworkError.notFound.errorMessage)
        XCTAssertTrue(viewModel.repos.isEmpty)
    }

    func test_followersViewModel_handlesNetworkErrorAndNonNetworkError() async {
        // Given: A ViewModel
        let viewModel = FollowersViewModel(networkService: mockService)

        // When: NetworkError occurs
        await mockService.configureFollowersResponse(.failure(NetworkError.rateLimitExceeded))
        await viewModel.fetchFollowers(for: "test")

        // Then: NetworkError message is displayed
        XCTAssertEqual(viewModel.errorMessage, NetworkError.rateLimitExceeded.errorMessage)

        // When: Non-NetworkError occurs
        struct CustomError: Error, LocalizedError {
            var errorDescription: String? { "Custom error occurred" }
        }
        await mockService.configureFollowersResponse(.failure(CustomError()))
        await viewModel.fetchFollowers(for: "test2")

        // Then: Generic error description is used
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("Custom error") ?? false)
    }

    func test_popularReposViewModel_handlesSearchErrors() async {
        // Given: Search failing
        await mockService.configureSearchResponse(.failure(NetworkError.forbidden))
        let viewModel = PopularReposViewModel(networkService: mockService)

        // When: Searching for popular repos
        await viewModel.fetchPopularRepositories(page: 1)

        // Then: Error is handled correctly
        XCTAssertEqual(viewModel.errorMessage, NetworkError.forbidden.errorMessage)
        XCTAssertTrue(viewModel.repositories.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Multiple Consecutive Errors

    func test_userViewModel_handlesMultipleConsecutiveErrors() async {
        // Given: A ViewModel
        let viewModel = UserViewModel(networkService: mockService)

        // When: Multiple errors occur in sequence
        let errors: [NetworkError] = [.notFound, .forbidden, .rateLimitExceeded]

        for (index, error) in errors.enumerated() {
            await mockService.configureUserResponse(.failure(error))
            await viewModel.fetchUser("user\(index)")

            // Then: Each error message is correctly set
            XCTAssertEqual(viewModel.errorMessage, error.errorMessage)
            XCTAssertNil(viewModel.user)
        }
    }

    func test_viewModel_alternatesBetweenSuccessAndError() async {
        // Given: A ViewModel
        let viewModel = UserViewModel(networkService: mockService)

        // When: Alternating between success and error
        await mockService.configureUserResponse(.success(TestFixtures.makeUser(id: 1)))
        await viewModel.fetchUser("user1")
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertNotNil(viewModel.user)

        await mockService.configureUserResponse(.failure(NetworkError.notFound))
        await viewModel.fetchUser("user2")
        XCTAssertNotNil(viewModel.errorMessage)

        await mockService.configureUserResponse(.success(TestFixtures.makeUser(id: 2)))
        await viewModel.fetchUser("user3")

        // Then: Error is cleared on success
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertNotNil(viewModel.user)
        XCTAssertEqual(viewModel.user?.id, 2)
    }

    // MARK: - Error Recovery Tests

    func test_userViewModel_canRecoverFromError() async {
        // Given: A ViewModel with an error state
        await mockService.configureUserResponse(.failure(NetworkError.networkError(
            NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        )))
        let viewModel = UserViewModel(networkService: mockService)
        await viewModel.fetchUser("offline")
        XCTAssertNotNil(viewModel.errorMessage)

        // When: Network becomes available and retry succeeds
        await mockService.configureUserResponse(.success(TestFixtures.makeUser()))
        await viewModel.fetchUser("online")

        // Then: ViewModel recovers successfully
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertNotNil(viewModel.user)
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_popularReposViewModel_recoversFromPaginationError() async {
        // Given: A ViewModel with first page loaded successfully
        let viewModel = PopularReposViewModel(networkService: mockService)
        await viewModel.fetchPopularRepositories(page: 1)
        let initialCount = viewModel.repositories.count
        XCTAssertNil(viewModel.errorMessage)

        // When: Second page fails
        await mockService.configureSearchResponse(.failure(NetworkError.rateLimitExceeded))
        await viewModel.loadNextPage()

        // Then: Error is shown but first page data persists
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.repositories.count, initialCount)

        // When: Retrying successfully
        await mockService.configureSearchResponse(.success(TestFixtures.makeRepoSearchResponse()))
        await viewModel.loadNextPage()

        // Then: New data is appended and error is cleared
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertGreaterThan(viewModel.repositories.count, initialCount)
    }

    // MARK: - Error State Consistency Tests

    func test_viewModel_doesNotLeakErrorBetweenInstances() async {
        // Given: First ViewModel with error
        let viewModel1 = UserViewModel(networkService: mockService)
        await mockService.configureUserResponse(.failure(NetworkError.notFound))
        await viewModel1.fetchUser("test")
        XCTAssertNotNil(viewModel1.errorMessage)

        // When: Creating second ViewModel
        let viewModel2 = UserViewModel(networkService: mockService)

        // Then: Second ViewModel has clean state
        XCTAssertNil(viewModel2.errorMessage)
        XCTAssertNil(viewModel2.user)
        XCTAssertFalse(viewModel2.isLoading)
    }

    func test_clearError_doesNotAffectOtherState() async {
        // Given: A ViewModel with user data and error
        let user = TestFixtures.makeUser()
        await mockService.configureUserResponse(.success(user))
        let viewModel = UserViewModel(networkService: mockService)
        await viewModel.fetchUser("test")

        // Introduce an error while keeping user
        await mockService.configureUserResponse(.failure(NetworkError.notFound))
        await viewModel.fetchUser("error")

        XCTAssertNotNil(viewModel.user)
        XCTAssertNotNil(viewModel.errorMessage)

        // When: Clearing error
        viewModel.clearError()

        // Then: Only error is cleared, user remains
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertNotNil(viewModel.user)
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Error Edge Cases

    func test_viewModel_handlesEmptyErrorMessage() async {
        // Given: An error with empty description
        struct EmptyError: Error, LocalizedError {
            var errorDescription: String? { "" }
        }

        await mockService.configureUserResponse(.failure(EmptyError()))
        let viewModel = UserViewModel(networkService: mockService)

        // When: Fetching with empty error
        await viewModel.fetchUser("test")

        // Then: ViewModel handles it gracefully
        XCTAssertNotNil(viewModel.errorMessage)
        // Falls back to generic message
        XCTAssertTrue(viewModel.errorMessage == "" || viewModel.errorMessage == "An unexpected error ocurred")
    }

    func test_viewModel_handlesVeryLongErrorMessage() async {
        // Given: An error with very long message
        let longMessage = String(repeating: "Error ", count: 1000)
        let error = NSError(
            domain: "test",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: longMessage]
        )

        await mockService.configureUserResponse(.failure(NetworkError.networkError(error)))
        let viewModel = UserViewModel(networkService: mockService)

        // When: Fetching with long error message
        await viewModel.fetchUser("test")

        // Then: Error message is set (truncation is UI concern)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertGreaterThan(viewModel.errorMessage?.count ?? 0, 1000)
    }

    func test_viewModel_handlesErrorWithSpecialCharacters() async {
        // Given: An error with special characters
        let specialMessage = "Error: <html>&nbsp;'quotes'\"double\" \n newline \t tab"
        let error = NSError(
            domain: "test",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: specialMessage]
        )

        await mockService.configureUserResponse(.failure(NetworkError.networkError(error)))
        let viewModel = UserViewModel(networkService: mockService)

        // When: Fetching with special character error
        await viewModel.fetchUser("test")

        // Then: Error message preserves special characters
        XCTAssertEqual(viewModel.errorMessage, specialMessage)
    }

    // MARK: - Error Timing Tests

    func test_errorMessage_isSetBeforeLoadingCompletes() async {
        // Given: A ViewModel with delayed error
        await mockService.setResponseDelay(TestConstants.shortDelay)
        await mockService.configureUserResponse(.failure(NetworkError.notFound))
        let viewModel = UserViewModel(networkService: mockService)

        // When: Fetching fails
        await viewModel.fetchUser("test")

        // Then: Error is set and loading is false
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_errorMessage_isPersistentAcrossReads() async {
        // Given: A ViewModel with an error
        await mockService.configureUserResponse(.failure(NetworkError.forbidden))
        let viewModel = UserViewModel(networkService: mockService)
        await viewModel.fetchUser("test")

        // When: Reading error message multiple times
        let message1 = viewModel.errorMessage
        let message2 = viewModel.errorMessage
        let message3 = viewModel.errorMessage

        // Then: Message is consistent
        XCTAssertEqual(message1, message2)
        XCTAssertEqual(message2, message3)
        XCTAssertEqual(message1, NetworkError.forbidden.errorMessage)
    }
}
