//
//  TestFixtures.swift
//  GithubSwiftUI-PracticeTests
//
//  Created by jesus on 13.11.25.
//

import Foundation
@testable import GithubSwiftUI_Practice

/// Test data builders and fixtures for consistent test data creation
enum TestFixtures {

    // MARK: - GHUser Fixtures

    static func makeUser(
        id: Int = 1,
        login: String = "testuser",
        avatarUrl: String = "https://avatars.githubusercontent.com/u/1",
        bio: String? = "Test bio",
        name: String? = "Test User",
        publicRepos: Int? = 10,
        followers: Int? = 100,
        following: Int? = 50
    ) -> GHUser {
        GHUser(
            id: id,
            login: login,
            avatarUrl: avatarUrl,
            bio: bio,
            name: name,
            publicRepos: publicRepos,
            followers: followers,
            following: following
        )
    }

    static func makeMinimalUser(id: Int = 1, login: String = "minimal") -> GHUser {
        GHUser(
            id: id,
            login: login,
            avatarUrl: "https://avatars.githubusercontent.com/u/\(id)",
            bio: nil,
            name: nil,
            publicRepos: nil,
            followers: 0,
            following: 0
        )
    }

    static func makeUserArray(count: Int = 3) -> [GHUser] {
        (1...count).map { index in
            makeUser(
                id: index,
                login: "user\(index)",
                name: "User \(index)"
            )
        }
    }

    // MARK: - GHRepo Fixtures

    static func makeRepo(
        id: Int = 1,
        name: String = "test-repo",
        fullName: String? = "testuser/test-repo",
        description: String? = "Test repository",
        language: String? = "Swift",
        visibility: String = "public",
        stargazersCount: Int? = 100,
        forksCount: Int? = 20,
        watchersCount: Int? = 50,
        openIssuesCount: Int? = 5,
        owner: RepositoryOwner? = nil
    ) -> GHRepo {
        GHRepo(
            id: id,
            name: name,
            fullName: fullName,
            description: description,
            language: language,
            visibility: visibility,
            stargazersCount: stargazersCount,
            forksCount: forksCount,
            watchersCount: watchersCount,
            openIssuesCount: openIssuesCount,
            owner: owner ?? makeRepositoryOwner()
        )
    }

    static func makeMinimalRepo(id: Int = 1, name: String = "minimal-repo") -> GHRepo {
        GHRepo(
            id: id,
            name: name,
            fullName: nil,
            description: nil,
            language: nil,
            visibility: "public",
            stargazersCount: nil,
            forksCount: nil,
            watchersCount: nil,
            openIssuesCount: nil,
            owner: nil
        )
    }

    static func makeRepoArray(count: Int = 3) -> [GHRepo] {
        (1...count).map { index in
            makeRepo(
                id: index,
                name: "repo\(index)",
                fullName: "user/repo\(index)",
                description: "Repository \(index)",
                stargazersCount: index * 100
            )
        }
    }

    // MARK: - RepositoryOwner Fixtures

    static func makeRepositoryOwner(
        login: String = "testowner",
        id: Int = 1,
        avatarUrl: String = "https://avatars.githubusercontent.com/u/1"
    ) -> RepositoryOwner {
        RepositoryOwner(login: login, id: id, avatarUrl: avatarUrl)
    }

    // MARK: - SearchResponse Fixtures

    static func makeSearchResponse<T>(
        totalCount: Int = 100,
        incompleteResults: Bool = false,
        items: [T]
    ) -> SearchResponse<T> {
        SearchResponse(
            totalCount: totalCount,
            incompleteResults: incompleteResults,
            items: items
        )
    }

    static func makeRepoSearchResponse(
        totalCount: Int = 100,
        itemCount: Int = 3
    ) -> SearchResponse<GHRepo> {
        makeSearchResponse(
            totalCount: totalCount,
            incompleteResults: false,
            items: makeRepoArray(count: itemCount)
        )
    }

    // MARK: - JSON Data Fixtures

    static func makeUserJSON(
        id: Int = 1,
        login: String = "testuser",
        includeOptionals: Bool = true
    ) -> String {
        var json = """
        {
            "id": \(id),
            "login": "\(login)",
            "avatar_url": "https://avatars.githubusercontent.com/u/\(id)",
            "followers": 100,
            "following": 50
        """

        if includeOptionals {
            json += """
            ,
            "bio": "Test bio",
            "name": "Test User",
            "public_repos": 10
            """
        }

        json += "\n}"
        return json
    }

    static func makeRepoJSON(
        id: Int = 1,
        name: String = "test-repo",
        includeOptionals: Bool = true
    ) -> String {
        var json = """
        {
            "id": \(id),
            "name": "\(name)",
            "visibility": "public"
        """

        if includeOptionals {
            json += """
            ,
            "full_name": "owner/\(name)",
            "description": "Test repository",
            "language": "Swift",
            "stargazers_count": 100,
            "forks_count": 20,
            "watchers_count": 50,
            "open_issues_count": 5,
            "owner": {
                "login": "testowner",
                "id": 1,
                "avatar_url": "https://avatars.githubusercontent.com/u/1"
            }
            """
        }

        json += "\n}"
        return json
    }
}

// MARK: - Test Constants

enum TestConstants {
    static let validUsername = "testuser"
    static let emptyUsername = ""
    static let longUsername = String(repeating: "a", count: 500)
    static let specialCharUsername = "test-user_123.test"
    static let unicodeUsername = "用户测试"

    static let validAvatarURL = "https://avatars.githubusercontent.com/u/1"
    static let defaultTimeout: TimeInterval = 5.0
    static let shortDelay: Duration = .milliseconds(50)
    static let mediumDelay: Duration = .milliseconds(200)
}
