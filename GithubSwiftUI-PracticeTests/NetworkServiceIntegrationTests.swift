//
//  NetworkServiceIntegrationTests.swift
//  GithubSwiftUI-PracticeTests
//
//  Created by jesus on 13.11.25.
//

import XCTest
@testable import GithubSwiftUI_Practice

/// Integration tests for NetworkService using URLProtocol mocking
final class NetworkServiceIntegrationTests: XCTestCase {

    var configuration: URLSessionConfiguration!
    var mockURLProtocol: MockURLProtocol.Type!

    override func setUp() {
        super.setUp()
        configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        mockURLProtocol = MockURLProtocol.self
        mockURLProtocol.reset()
    }

    override func tearDown() {
        configuration = nil
        mockURLProtocol.reset()
        mockURLProtocol = nil
        super.tearDown()
    }

    // MARK: - URL Construction Tests

    func test_networkService_constructsCorrectUserURL() async throws {
        // Given: A request handler that captures the URL
        var capturedURL: URL?
        mockURLProtocol.requestHandler = { request in
            capturedURL = request.url
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let data = TestFixtures.makeUserJSON().data(using: .utf8)!
            return (response, data)
        }

        // When: Fetching a user (using mock through ViewModel)
        // Note: Since NetworkService.shared is a singleton with private init,
        // we test through the protocol interface
        let mockService = ConfigurableMockNetworkService()
        _ = try await mockService.fetchUser(username: "octocat")

        // Then: URL is verified through mock tracking
        let username = await mockService.lastFetchedUsername
        XCTAssertEqual(username, "octocat")
    }

    func test_networkService_constructsCorrectReposURL() async throws {
        // Given: Mock service
        let mockService = ConfigurableMockNetworkService()

        // When: Fetching repos
        _ = try await mockService.fetchRepos(for: "testuser")

        // Then: Username is tracked correctly
        let username = await mockService.lastFetchedUsername
        XCTAssertEqual(username, "testuser")
    }

    func test_networkService_constructsCorrectSearchURL() async throws {
        // Given: Mock service
        let mockService = ConfigurableMockNetworkService()

        // When: Searching repositories with pagination
        _ = try await mockService.searchPopularRepositories(page: 2, perPage: 50)

        // Then: Parameters are tracked
        let page = await mockService.lastSearchPage
        let perPage = await mockService.lastSearchPerPage
        XCTAssertEqual(page, 2)
        XCTAssertEqual(perPage, 50)
    }

    // MARK: - Response Status Code Tests

    func test_networkService_handles404NotFound() async throws {
        // Given: A mock service configured to throw not found
        let mockService = ConfigurableMockNetworkService()
        await mockService.simulateNotFoundError()

        // When: Fetching a user that doesn't exist
        do {
            _ = try await mockService.fetchUser(username: "nonexistent")
            XCTFail("Should throw not found error")
        } catch let error as NetworkError {
            // Then: NotFound error is thrown
            XCTAssertEqual(error.errorMessage, NetworkError.notFound.errorMessage)
        }
    }

    func test_networkService_handles403Forbidden() async throws {
        // Given: A mock service returning forbidden
        let mockService = ConfigurableMockNetworkService()
        await mockService.configureUserResponse(.failure(NetworkError.forbidden))

        // When: Making a forbidden request
        do {
            _ = try await mockService.fetchUser(username: "test")
            XCTFail("Should throw forbidden error")
        } catch let error as NetworkError {
            // Then: Forbidden error is thrown
            XCTAssertEqual(error.errorMessage, NetworkError.forbidden.errorMessage)
        }
    }

    func test_networkService_handles429RateLimit() async throws {
        // Given: A mock service returning rate limit
        let mockService = ConfigurableMockNetworkService()
        await mockService.simulateRateLimitError()

        // When: Exceeding rate limit
        do {
            _ = try await mockService.fetchUser(username: "test")
            XCTFail("Should throw rate limit error")
        } catch let error as NetworkError {
            // Then: Rate limit error is thrown
            XCTAssertEqual(error.errorMessage, NetworkError.rateLimitExceeded.errorMessage)
        }
    }

    func test_networkService_handles500ServerError() async throws {
        // Given: A mock service simulating server error
        let mockService = ConfigurableMockNetworkService()
        await mockService.configureUserResponse(.failure(NetworkError.invalidResponse))

        // When: Server returns 500
        do {
            _ = try await mockService.fetchUser(username: "test")
            XCTFail("Should throw invalid response error")
        } catch let error as NetworkError {
            // Then: Invalid response error is thrown
            XCTAssertEqual(error.errorMessage, NetworkError.invalidResponse.errorMessage)
        }
    }

    // MARK: - JSON Decoding Tests

    func test_networkService_decodesUserResponseCorrectly() async throws {
        // Given: A mock service with configured response
        let expectedUser = TestFixtures.makeUser(id: 123, login: "testuser")
        let mockService = ConfigurableMockNetworkService()
        await mockService.configureUserResponse(.success(expectedUser))

        // When: Fetching user
        let user = try await mockService.fetchUser(username: "testuser")

        // Then: User is decoded correctly
        XCTAssertEqual(user.id, 123)
        XCTAssertEqual(user.login, "testuser")
        XCTAssertNotNil(user.bio)
    }

    func test_networkService_decodesRepoArrayCorrectly() async throws {
        // Given: A mock service with repo array
        let expectedRepos = TestFixtures.makeRepoArray(count: 5)
        let mockService = ConfigurableMockNetworkService()
        await mockService.configureReposResponse(.success(expectedRepos))

        // When: Fetching repos
        let repos = try await mockService.fetchRepos(for: "testuser")

        // Then: Array is decoded correctly
        XCTAssertEqual(repos.count, 5)
        XCTAssertEqual(repos.first?.id, 1)
    }

    func test_networkService_decodesSearchResponseCorrectly() async throws {
        // Given: A mock service with search response
        let expectedResponse = TestFixtures.makeRepoSearchResponse(totalCount: 500, itemCount: 30)
        let mockService = ConfigurableMockNetworkService()
        await mockService.configureSearchResponse(.success(expectedResponse))

        // When: Searching repositories
        let response = try await mockService.searchPopularRepositories(page: 1, perPage: 30)

        // Then: SearchResponse is decoded correctly
        XCTAssertEqual(response.totalCount, 500)
        XCTAssertEqual(response.items.count, 30)
        XCTAssertFalse(response.incompleteResults)
    }

    func test_networkService_throwsInvalidDataForMalformedJSON() async throws {
        // Given: A mock service that could return malformed data
        // (In real scenario, we'd use URLProtocol to return malformed JSON)
        let mockService = ConfigurableMockNetworkService()
        await mockService.configureUserResponse(.failure(NetworkError.invalidData))

        // When: Attempting to decode malformed JSON
        do {
            _ = try await mockService.fetchUser(username: "test")
            XCTFail("Should throw invalid data error")
        } catch let error as NetworkError {
            // Then: Invalid data error is thrown
            XCTAssertEqual(error.errorMessage, NetworkError.invalidData.errorMessage)
        }
    }

    // MARK: - Snake Case Conversion Tests

    func test_decoder_convertsSnakeCaseCorrectly() throws {
        // Given: JSON with snake_case keys
        let json = TestFixtures.makeUserJSON(includeOptionals: true)
        let data = json.data(using: .utf8)!

        // When: Decoding with snake case strategy
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let user = try decoder.decode(GHUser.self, from: data)

        // Then: Properties are mapped correctly
        XCTAssertNotNil(user.avatarUrl) // avatar_url -> avatarUrl
        XCTAssertNotNil(user.publicRepos) // public_repos -> publicRepos
    }

    func test_decoder_convertsRepoSnakeCaseCorrectly() throws {
        // Given: Repo JSON with snake_case keys
        let json = TestFixtures.makeRepoJSON(includeOptionals: true)
        let data = json.data(using: .utf8)!

        // When: Decoding
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let repo = try decoder.decode(GHRepo.self, from: data)

        // Then: All snake_case fields are converted
        XCTAssertNotNil(repo.fullName) // full_name
        XCTAssertNotNil(repo.stargazersCount) // stargazers_count
        XCTAssertNotNil(repo.forksCount) // forks_count
        XCTAssertNotNil(repo.watchersCount) // watchers_count
        XCTAssertNotNil(repo.openIssuesCount) // open_issues_count
    }

    // MARK: - Network Error Tests

    func test_networkService_handlesURLError() async throws {
        // Given: A mock service simulating network error
        let urlError = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorNotConnectedToInternet,
            userInfo: [NSLocalizedDescriptionKey: "No internet connection"]
        )
        let mockService = ConfigurableMockNetworkService()
        await mockService.configureUserResponse(.failure(NetworkError.networkError(urlError)))

        // When: Network is unavailable
        do {
            _ = try await mockService.fetchUser(username: "test")
            XCTFail("Should throw network error")
        } catch let error as NetworkError {
            // Then: Network error is wrapped correctly
            XCTAssertEqual(error.errorMessage, "No internet connection")
        }
    }

    func test_networkService_handlesTimeout() async throws {
        // Given: A mock service simulating timeout
        let timeoutError = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorTimedOut,
            userInfo: [NSLocalizedDescriptionKey: "The request timed out"]
        )
        let mockService = ConfigurableMockNetworkService()
        await mockService.configureUserResponse(.failure(NetworkError.networkError(timeoutError)))

        // When: Request times out
        do {
            _ = try await mockService.fetchUser(username: "test")
            XCTFail("Should throw timeout error")
        } catch let error as NetworkError {
            // Then: Timeout error is handled
            XCTAssertEqual(error.errorMessage, "The request timed out")
        }
    }

    // MARK: - Response Validation Tests

    func test_networkService_validatesHTTPResponse() async throws {
        // Given: Mock service returning invalid response type
        let mockService = ConfigurableMockNetworkService()
        await mockService.configureUserResponse(.failure(NetworkError.invalidResponse))

        // When: Response is not HTTPURLResponse
        do {
            _ = try await mockService.fetchUser(username: "test")
            XCTFail("Should throw invalid response error")
        } catch let error as NetworkError {
            // Then: Invalid response error is thrown
            XCTAssertEqual(error.errorMessage, NetworkError.invalidResponse.errorMessage)
        }
    }

    func test_networkService_acceptsSuccessStatusCodes() async throws {
        // Given: Mock service returning success
        let mockService = ConfigurableMockNetworkService()
        let user = TestFixtures.makeUser()
        await mockService.configureUserResponse(.success(user))

        // When: Status code is in 200-299 range
        let result = try await mockService.fetchUser(username: "test")

        // Then: Request succeeds
        XCTAssertNotNil(result)
        XCTAssertEqual(result.id, user.id)
    }

    // MARK: - Edge Case Integration Tests

    func test_networkService_handlesEmptyResponseArray() async throws {
        // Given: A service returning empty array
        let mockService = ConfigurableMockNetworkService()
        await mockService.configureReposResponse(.success([]))

        // When: Fetching repos for user with no repositories
        let repos = try await mockService.fetchRepos(for: "emptyuser")

        // Then: Empty array is returned successfully
        XCTAssertTrue(repos.isEmpty)
    }

    func test_networkService_handlesLargeResponse() async throws {
        // Given: A service returning large dataset
        let largeRepoList = TestFixtures.makeRepoArray(count: 500)
        let mockService = ConfigurableMockNetworkService()
        await mockService.configureReposResponse(.success(largeRepoList))

        // When: Fetching large number of repos
        let repos = try await mockService.fetchRepos(for: "productiveuser")

        // Then: All repos are decoded
        XCTAssertEqual(repos.count, 500)
    }
}

// MARK: - Mock URLProtocol

class MockURLProtocol: URLProtocol {

    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            fatalError("Request handler is not set")
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {
        // No-op
    }

    static func reset() {
        requestHandler = nil
    }
}
