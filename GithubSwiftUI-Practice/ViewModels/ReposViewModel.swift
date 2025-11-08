//
//  ReposViewModel.swift
//  GithubSwiftUI-Practice
//
//  Created by jesus on 08.11.25.
//

import Foundation

@MainActor
@Observable
class ReposViewModel {

    var repos: [GHRepo] = []
    var isLoading: Bool = false
    var errorMessage: String?

    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }

    func fetchRepos(for username: String) async {
        isLoading = true
        errorMessage = nil

        do {
            repos = try await networkService.fetchRepos(for: username)
        } catch let error as NetworkError {
            errorMessage = error.errorMessage
        } catch {
            errorMessage = "An unexpected error occurred"
        }

        isLoading = false
    }
}
