//
//  ConfigurableMockNetworkService.swift
//  GithubSwiftUI-PracticeTests
//
//  Created by jesus on 13.11.25.
//

import Foundation
@testable import GithubSwiftUI_Practice

/// Advanced mock network service with configurable responses, delays, and call tracking
actor ConfigurableMockNetworkService: NetworkServiceProtocol {

    // MARK: - Configuration

    var userResponse: Result<GHUser, Error>?
    var reposResponse: Result<[GHRepo], Error>?
    var followersResponse: Result<[GHUser], Error>?
    var searchResponse: Result<SearchResponse<GHRepo>, Error>?

    var responseDelay: Duration = .zero
    var shouldFailNextCall = false

    // MARK: - Call Tracking

    private(set) var fetchUserCallCount = 0
    private(set) var fetchReposCallCount = 0
    private(set) var fetchFollowersCallCount = 0
    private(set) var searchCallCount = 0

    private(set) var lastFetchedUsername: String?
    private(set) var lastSearchPage: Int?
    private(set) var lastSearchPerPage: Int?

    // MARK: - Response Configuration Methods

    func configureUserResponse(_ result: Result<GHUser, Error>) {
        userResponse = result
    }

    func configureReposResponse(_ result: Result<[GHRepo], Error>) {
        reposResponse = result
    }

    func configureFollowersResponse(_ result: Result<[GHUser], Error>) {
        followersResponse = result
    }

    func configureSearchResponse(_ result: Result<SearchResponse<GHRepo>, Error>) {
        searchResponse = result
    }

    func setResponseDelay(_ delay: Duration) {
        responseDelay = delay
    }

    func setFailNextCall(_ shouldFail: Bool) {
        shouldFailNextCall = shouldFail
    }

    // MARK: - Reset

    func reset() {
        userResponse = nil
        reposResponse = nil
        followersResponse = nil
        searchResponse = nil
        responseDelay = .zero
        shouldFailNextCall = false

        fetchUserCallCount = 0
        fetchReposCallCount = 0
        fetchFollowersCallCount = 0
        searchCallCount = 0

        lastFetchedUsername = nil
        lastSearchPage = nil
        lastSearchPerPage = nil
    }

    // MARK: - NetworkServiceProtocol Implementation

    func fetchUser(username: String) async throws -> GHUser {
        fetchUserCallCount += 1
        lastFetchedUsername = username

        if responseDelay > .zero {
            try await Task.sleep(for: responseDelay)
        }

        if shouldFailNextCall {
            shouldFailNextCall = false
            throw NetworkError.invalidResponse
        }

        if let response = userResponse {
            switch response {
            case .success(let user):
                return user
            case .failure(let error):
                throw error
            }
        }

        // Default response
        return TestFixtures.makeUser(login: username)
    }

    func fetchRepos(for username: String) async throws -> [GHRepo] {
        fetchReposCallCount += 1
        lastFetchedUsername = username

        if responseDelay > .zero {
            try await Task.sleep(for: responseDelay)
        }

        if shouldFailNextCall {
            shouldFailNextCall = false
            throw NetworkError.invalidResponse
        }

        if let response = reposResponse {
            switch response {
            case .success(let repos):
                return repos
            case .failure(let error):
                throw error
            }
        }

        // Default response
        return TestFixtures.makeRepoArray(count: 2)
    }

    func fetchFollowers(for username: String) async throws -> [GHUser] {
        fetchFollowersCallCount += 1
        lastFetchedUsername = username

        if responseDelay > .zero {
            try await Task.sleep(for: responseDelay)
        }

        if shouldFailNextCall {
            shouldFailNextCall = false
            throw NetworkError.invalidResponse
        }

        if let response = followersResponse {
            switch response {
            case .success(let followers):
                return followers
            case .failure(let error):
                throw error
            }
        }

        // Default response
        return TestFixtures.makeUserArray(count: 2)
    }

    func searchPopularRepositories(page: Int, perPage: Int) async throws -> SearchResponse<GHRepo> {
        searchCallCount += 1
        lastSearchPage = page
        lastSearchPerPage = perPage

        if responseDelay > .zero {
            try await Task.sleep(for: responseDelay)
        }

        if shouldFailNextCall {
            shouldFailNextCall = false
            throw NetworkError.invalidResponse
        }

        if let response = searchResponse {
            switch response {
            case .success(let searchResult):
                return searchResult
            case .failure(let error):
                throw error
            }
        }

        // Default response with pagination simulation
        return TestFixtures.makeRepoSearchResponse(
            totalCount: 100,
            itemCount: perPage
        )
    }
}

// MARK: - Convenience Configuration Methods

extension ConfigurableMockNetworkService {

    func simulateNetworkError() {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        configureUserResponse(.failure(NetworkError.networkError(error)))
        configureReposResponse(.failure(NetworkError.networkError(error)))
        configureFollowersResponse(.failure(NetworkError.networkError(error)))
        configureSearchResponse(.failure(NetworkError.networkError(error)))
    }

    func simulateNotFoundError() {
        configureUserResponse(.failure(NetworkError.notFound))
        configureReposResponse(.failure(NetworkError.notFound))
        configureFollowersResponse(.failure(NetworkError.notFound))
        configureSearchResponse(.failure(NetworkError.notFound))
    }

    func simulateRateLimitError() {
        configureUserResponse(.failure(NetworkError.rateLimitExceeded))
        configureReposResponse(.failure(NetworkError.rateLimitExceeded))
        configureFollowersResponse(.failure(NetworkError.rateLimitExceeded))
        configureSearchResponse(.failure(NetworkError.rateLimitExceeded))
    }

    func simulateSuccessWithDelay(_ delay: Duration) {
        setResponseDelay(delay)
        configureUserResponse(.success(TestFixtures.makeUser()))
        configureReposResponse(.success(TestFixtures.makeRepoArray()))
        configureFollowersResponse(.success(TestFixtures.makeUserArray()))
        configureSearchResponse(.success(TestFixtures.makeRepoSearchResponse()))
    }

    func configureEmptyResults() {
        configureReposResponse(.success([]))
        configureFollowersResponse(.success([]))
        configureSearchResponse(.success(
            SearchResponse(totalCount: 0, incompleteResults: false, items: [])
        ))
    }
}
