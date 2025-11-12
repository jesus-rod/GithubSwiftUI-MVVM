//
//  NetworkServiceTests.swift
//  GithubSwiftUI-PracticeTests
//
//  Created by jesus on 08.11.25.
//

import XCTest
@testable import GithubSwiftUI_Practice

final class NetworkServiceTests: XCTestCase {

    // MARK: - NetworkError Tests

    func test_networkError_invalidURL_hasCorrectMessage() {
        let error = NetworkError.invalidURL
        XCTAssertEqual(error.errorMessage, "Invalid URL")
    }

    func test_networkError_invalidResponse_hasCorrectMessage() {
        let error = NetworkError.invalidResponse
        XCTAssertEqual(error.errorMessage, "Invalid server response")
    }

    func test_networkError_invalidData_hasCorrectMessage() {
        let error = NetworkError.invalidData
        XCTAssertEqual(error.errorMessage, "Invalid data")
    }

    func test_networkError_notFound_hasCorrectMessage() {
        let error = NetworkError.notFound
        XCTAssertEqual(error.errorMessage, "User or resource not found")
    }

    func test_networkError_forbidden_hasCorrectMessage() {
        let error = NetworkError.forbidden
        XCTAssertEqual(error.errorMessage, "Access forbidden")
    }

    func test_networkError_rateLimitExceeded_hasCorrectMessage() {
        let error = NetworkError.rateLimitExceeded
        XCTAssertEqual(error.errorMessage, "GitHub API rate limit exceeded. Try again later")
    }

    func test_networkError_networkError_hasCorrectMessage() {
        let underlyingError = NSError(domain: "test", code: 42, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let error = NetworkError.networkError(underlyingError)
        XCTAssertEqual(error.errorMessage, "Test error")
    }

    // MARK: - Model Decoding Tests

    func test_GHUser_decodesCorrectly() throws {
        let json = """
        {
            "id": 123,
            "login": "octocat",
            "avatar_url": "https://avatars.githubusercontent.com/u/583231",
            "bio": "The Octocat",
            "name": "The Octocat",
            "public_repos": 8,
            "followers": 1000,
            "following": 10
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let user = try decoder.decode(GHUser.self, from: data)

        XCTAssertEqual(user.id, 123)
        XCTAssertEqual(user.login, "octocat")
        XCTAssertEqual(user.avatarUrl, "https://avatars.githubusercontent.com/u/583231")
        XCTAssertEqual(user.bio, "The Octocat")
        XCTAssertEqual(user.name, "The Octocat")
        XCTAssertEqual(user.publicRepos, 8)
        XCTAssertEqual(user.followers, 1000)
        XCTAssertEqual(user.following, 10)
    }

    func test_GHUser_decodesWithOptionalFields() throws {
        let json = """
        {
            "id": 123,
            "login": "octocat",
            "avatar_url": "https://avatars.githubusercontent.com/u/583231",
            "followers": 1000,
            "following": 10
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let user = try decoder.decode(GHUser.self, from: data)

        XCTAssertEqual(user.id, 123)
        XCTAssertEqual(user.login, "octocat")
        XCTAssertNil(user.bio)
        XCTAssertNil(user.name)
        XCTAssertNil(user.publicRepos)
    }

    func test_GHRepo_decodesCorrectly() throws {
        let json = """
        {
            "id": 456,
            "name": "Hello-World",
            "description": "My first repository",
            "language": "Swift",
            "visibility": "public"
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let repo = try decoder.decode(GHRepo.self, from: data)

        XCTAssertEqual(repo.id, 456)
        XCTAssertEqual(repo.name, "Hello-World")
        XCTAssertEqual(repo.description, "My first repository")
        XCTAssertEqual(repo.language, "Swift")
        XCTAssertEqual(repo.visibility, "public")
    }

    func test_GHRepo_decodesWithOptionalFields() throws {
        let json = """
        {
            "id": 456,
            "name": "Hello-World",
            "visibility": "public"
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let repo = try decoder.decode(GHRepo.self, from: data)

        XCTAssertEqual(repo.id, 456)
        XCTAssertEqual(repo.name, "Hello-World")
        XCTAssertNil(repo.description)
        XCTAssertNil(repo.language)
        XCTAssertEqual(repo.visibility, "public")
    }

    func test_GHRepo_arrayDecodesCorrectly() throws {
        let json = """
        [
            {
                "id": 1,
                "name": "repo1",
                "description": "First repo",
                "language": "Swift",
                "visibility": "public"
            },
            {
                "id": 2,
                "name": "repo2",
                "visibility": "private"
            }
        ]
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let repos = try decoder.decode([GHRepo].self, from: data)

        XCTAssertEqual(repos.count, 2)
        XCTAssertEqual(repos[0].name, "repo1")
        XCTAssertEqual(repos[0].description, "First repo")
        XCTAssertEqual(repos[1].name, "repo2")
        XCTAssertNil(repos[1].description)
    }

    // MARK: - Model Tests

    func test_GHUser_conformsToIdentifiable() {
        let user = GHUser(id: 1, login: "test", avatarUrl: "url", bio: nil, name: nil, publicRepos: nil, followers: 0, following: 0)
        XCTAssertEqual(user.id, 1)
    }

    func test_GHRepo_conformsToIdentifiable() {
        let repo = GHRepo(id: 42, name: "test-repo", fullName: nil, description: nil, language: nil, visibility: "public", stargazersCount: nil, forksCount: nil, watchersCount: nil, openIssuesCount: nil, owner: nil)
        XCTAssertEqual(repo.id, 42)
    }

    // MARK: - SearchResponse Tests

    func test_SearchResponse_decodesCorrectly() throws {
        let json = """
        {
            "total_count": 100,
            "incomplete_results": false,
            "items": [
                {
                    "id": 1,
                    "name": "repo1",
                    "visibility": "public"
                },
                {
                    "id": 2,
                    "name": "repo2",
                    "visibility": "private"
                }
            ]
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let response = try decoder.decode(SearchResponse<GHRepo>.self, from: data)

        XCTAssertEqual(response.totalCount, 100)
        XCTAssertFalse(response.incompleteResults)
        XCTAssertEqual(response.items.count, 2)
        XCTAssertEqual(response.items[0].name, "repo1")
        XCTAssertEqual(response.items[1].name, "repo2")
    }

    func test_SearchResponse_decodesWithEmptyItems() throws {
        let json = """
        {
            "total_count": 0,
            "incomplete_results": false,
            "items": []
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let response = try decoder.decode(SearchResponse<GHRepo>.self, from: data)

        XCTAssertEqual(response.totalCount, 0)
        XCTAssertFalse(response.incompleteResults)
        XCTAssertTrue(response.items.isEmpty)
    }

    // MARK: - RepositoryOwner Tests

    func test_RepositoryOwner_decodesCorrectly() throws {
        let json = """
        {
            "login": "octocat",
            "id": 1,
            "avatar_url": "https://github.com/images/error/octocat_happy.gif"
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let owner = try decoder.decode(RepositoryOwner.self, from: data)

        XCTAssertEqual(owner.login, "octocat")
        XCTAssertEqual(owner.id, 1)
        XCTAssertEqual(owner.avatarUrl, "https://github.com/images/error/octocat_happy.gif")
    }

    // MARK: - GHRepo with Search Fields Tests

    func test_GHRepo_decodesWithSearchFields() throws {
        let json = """
        {
            "id": 456,
            "name": "Hello-World",
            "full_name": "octocat/Hello-World",
            "description": "My first repository",
            "language": "Swift",
            "visibility": "public",
            "stargazers_count": 1000,
            "forks_count": 200,
            "watchers_count": 500,
            "open_issues_count": 10,
            "owner": {
                "login": "octocat",
                "id": 1,
                "avatar_url": "https://github.com/octocat.png"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let repo = try decoder.decode(GHRepo.self, from: data)

        XCTAssertEqual(repo.id, 456)
        XCTAssertEqual(repo.name, "Hello-World")
        XCTAssertEqual(repo.fullName, "octocat/Hello-World")
        XCTAssertEqual(repo.description, "My first repository")
        XCTAssertEqual(repo.language, "Swift")
        XCTAssertEqual(repo.visibility, "public")
        XCTAssertEqual(repo.stargazersCount, 1000)
        XCTAssertEqual(repo.forksCount, 200)
        XCTAssertEqual(repo.watchersCount, 500)
        XCTAssertEqual(repo.openIssuesCount, 10)
        XCTAssertNotNil(repo.owner)
        XCTAssertEqual(repo.owner?.login, "octocat")
    }

    func test_GHRepo_decodesWithoutOwner() throws {
        let json = """
        {
            "id": 456,
            "name": "Hello-World",
            "visibility": "public",
            "stargazers_count": 1000
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let repo = try decoder.decode(GHRepo.self, from: data)

        XCTAssertEqual(repo.id, 456)
        XCTAssertEqual(repo.name, "Hello-World")
        XCTAssertEqual(repo.stargazersCount, 1000)
        XCTAssertNil(repo.owner)
        XCTAssertNil(repo.fullName)
        XCTAssertNil(repo.description)
    }
}
