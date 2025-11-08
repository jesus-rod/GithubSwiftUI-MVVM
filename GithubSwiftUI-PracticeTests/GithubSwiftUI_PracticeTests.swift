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
        if (shouldFail) {
            throw NetworkError.invalidResponse
        }
        return GHUser(id: 1,
                      login: username,
                      avatarUrl: "test", bio: "testBio",
                      name: "Test Name", publicRepos: 10, followers: 10, following: 10)
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
}
