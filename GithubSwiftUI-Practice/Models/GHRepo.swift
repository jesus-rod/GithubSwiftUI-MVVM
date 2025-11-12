//
//  GHRepo.swift
//  GithubSwiftUI-Practice
//
//  Created by jesus on 08.11.25.
//

import Foundation

struct GHRepo: Decodable, Identifiable, Sendable {
    let id: Int
    let name: String
    let fullName: String?
    let description: String?
    let language: String?
    let visibility: String
    let stargazersCount: Int?
    let forksCount: Int?
    let watchersCount: Int?
    let openIssuesCount: Int?
    let owner: RepositoryOwner?
}

struct RepositoryOwner: Decodable, Sendable {
    let login: String
    let id: Int
    let avatarUrl: String
}
