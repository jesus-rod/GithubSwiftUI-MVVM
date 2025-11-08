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
        let repo = GHRepo(id: 42, name: "test-repo", description: nil, language: nil, visibility: "public")
        XCTAssertEqual(repo.id, 42)
    }
}
