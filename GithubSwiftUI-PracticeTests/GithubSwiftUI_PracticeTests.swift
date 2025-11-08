//
//  GithubSwiftUI_PracticeTests.swift
//  GithubSwiftUI-PracticeTests
//
//  Created by jesus on 08.11.25.
//

import XCTest
@testable import GithubSwiftUI_Practice

class MockNetworkService: NetworkServiceProtocol {
    
    
    var shouldFail: Bool = false
    func fetchUser(username: String) async throws -> GithubSwiftUI_Practice.GHUser {
        if shouldFail {
            throw NetworkError.invalidResponse
        }
        return GHUser(id: 1,
                      login: username,
                      avatarUrl: "test", bio: "testBio",
                      name: "Test Name", publicRepos: 10, followers: 10, following: 10)
    }
    
    func fetchRepos(for username: String) async throws -> [GithubSwiftUI_Practice.GHRepo] {
        if shouldFail {
            throw NetworkError.invalidResponse
        }
        return [
            GHRepo(id: 1, name: "iOS Repo", description: "SwiftUI things", language: "Swift", visibility: "Public"),
            GHRepo(id: 1, name: "TypeScript Repo", description: "Testing Advanced TS features", language: "Typescript", visibility: "Private")
        ]
    }
    
    func fetchFollowers(for username: String) async throws -> [GithubSwiftUI_Practice.GHUser] {
        if shouldFail {
            throw NetworkError.invalidResponse
        }
        return [
            GHUser(id: 1, login: "follower1", avatarUrl: "test1", bio: "Test Bio 1", name: "Follower One", publicRepos: 5, followers: 20, following: 15),
            GHUser(id: 2, login: "follower2", avatarUrl: "test2", bio: "Test Bio 2", name: "Follower Two", publicRepos: 8, followers: 30, following: 25)
        ]
    }
    
    
}

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
        mockNetworkService.shouldFail = true
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
        mockNetworkService.shouldFail = true
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
        mockNetworkService.shouldFail = true
        let viewModel = FollowersViewModel(networkService: mockNetworkService)
        
        await viewModel.fetchFollowers(for: "test-user")
        XCTAssertTrue(viewModel.followers.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }
}
