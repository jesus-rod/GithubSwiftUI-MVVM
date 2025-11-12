//
//  FollowersViewModel.swift
//  GithubSwiftUI-Practice
//
//  Created by jesus on 08.11.25.
//

import Foundation
@MainActor
@Observable
class FollowersViewModel {
    var followers: [GHUser] = []
    var isLoading = false
    var errorMessage: String?
    
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol = NetworkService.shared) {
        self.networkService = networkService
    }
    
    
    func fetchFollowers(for username: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            followers = try await networkService.fetchFollowers(for: username)
        } catch {
            errorMessage = (error as? NetworkError)?.errorMessage ?? error.localizedDescription
        }
        
        isLoading = false
    }
}
