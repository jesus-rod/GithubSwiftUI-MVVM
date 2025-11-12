//
//  MockNetworkService.swift
//  GithubSwiftUI-Practice
//
//  Created by jesus on 09.11.25.
//

@testable import GithubSwiftUI_Practice
actor MockNetworkService: NetworkServiceProtocol {

    var shouldFail: Bool = false
    
    func setShouldFail(_ value: Bool) {
        shouldFail = value
    }

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
            GHRepo(id: 1, name: "iOS Repo", fullName: "user/iOS-Repo", description: "SwiftUI things", language: "Swift", visibility: "Public", stargazersCount: 100, forksCount: 20, watchersCount: 50, openIssuesCount: 5, owner: nil),
            GHRepo(id: 2, name: "TypeScript Repo", fullName: "user/TypeScript-Repo", description: "Testing Advanced TS features", language: "Typescript", visibility: "Private", stargazersCount: 50, forksCount: 10, watchersCount: 25, openIssuesCount: 2, owner: nil)
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

    func searchPopularRepositories(page: Int, perPage: Int) async throws -> SearchResponse<GHRepo> {
        if shouldFail {
            throw NetworkError.invalidResponse
        }

        let mockRepos = [
            GHRepo(id: 1, name: "awesome-repo", fullName: "octocat/awesome-repo", description: "The most awesome repo", language: "Swift", visibility: "public", stargazersCount: 10000, forksCount: 2000, watchersCount: 5000, openIssuesCount: 50, owner: RepositoryOwner(login: "octocat", id: 1, avatarUrl: "https://github.com/octocat.png")),
            GHRepo(id: 2, name: "cool-project", fullName: "github/cool-project", description: "A cool project", language: "JavaScript", visibility: "public", stargazersCount: 8000, forksCount: 1500, watchersCount: 4000, openIssuesCount: 30, owner: RepositoryOwner(login: "github", id: 2, avatarUrl: "https://github.com/github.png")),
            GHRepo(id: 3, name: "popular-lib", fullName: "developer/popular-lib", description: "Popular library", language: "Python", visibility: "public", stargazersCount: 5000, forksCount: 800, watchersCount: 2500, openIssuesCount: 20, owner: RepositoryOwner(login: "developer", id: 3, avatarUrl: "https://github.com/developer.png"))
        ]

        return SearchResponse(totalCount: 100, incompleteResults: false, items: mockRepos)
    }
}
