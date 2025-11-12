//
//  SearchResponse.swift
//  GithubSwiftUI-Practice
//
//  Created by jesus on 08.11.25.
//

import Foundation

struct SearchResponse<T: Decodable & Sendable>: Decodable, Sendable {
    let totalCount: Int
    let incompleteResults: Bool
    let items: [T]
}
