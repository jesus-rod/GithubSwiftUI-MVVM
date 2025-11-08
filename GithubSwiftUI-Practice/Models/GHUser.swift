//
//  GHUser.swift
//  GithubSwiftUI-Practice
//
//  Created by jesus on 08.11.25.
//

public struct GHUser: Decodable, Identifiable {
    public let id: Int
    let login: String
    let avatarUrl: String
    let bio: String?
    let name: String?
    let publicRepos: Int?
    let followers: Int?
    let following: Int?
    
    public init(id: Int, login: String, avatarUrl: String, bio: String?, name: String?, publicRepos: Int?, followers: Int?, following: Int?) {
        self.id = id
        self.login = login
        self.avatarUrl = avatarUrl
        self.bio = bio
        self.name = name
        self.publicRepos = publicRepos
        self.followers = followers
        self.following = following
    }
}


