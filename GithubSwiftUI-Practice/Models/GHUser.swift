//
//  GHUser.swift
//  GithubSwiftUI-Practice
//
//  Created by jesus on 08.11.25.
//

struct GHUser: Decodable, Identifiable {
    let id: Int
    let login: String
    let avatarUrl: String
    let bio: String?
    let name: String?
    let publicRepos: Int?
    let followers: Int
    let following: Int
}
