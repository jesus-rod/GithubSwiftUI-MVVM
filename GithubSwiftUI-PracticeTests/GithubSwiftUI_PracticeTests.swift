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
    }
    
    func test_viewModelFetchesReposFailure() async {
        let mockNetworkService = MockNetworkService()
        mockNetworkService.shouldFail = true
        let viewModel = ReposViewModel(networkService: mockNetworkService)
        await viewModel.fetchRepos(for: "test-user")
        XCTAssertNil(viewModel.repos)
    }
}
