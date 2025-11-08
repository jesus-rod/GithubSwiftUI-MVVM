//
//  GHRepo.swift
//  GithubSwiftUI-Practice
//
//  Created by jesus on 08.11.25.
//

import Foundation

struct GHRepo: Decodable {
    let id: Int
    let name: String
    let description: String?
    let language: String?
    let visibility: String
}
