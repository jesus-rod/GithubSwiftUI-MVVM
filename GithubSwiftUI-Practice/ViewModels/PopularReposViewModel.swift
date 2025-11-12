//
//  PopularReposViewModel.swift
//  GithubSwiftUI-Practice
//
//  Created by jesus on 08.11.25.
//

import Foundation

@MainActor
@Observable
class PopularReposViewModel {

    var repositories: [GHRepo] = []
    var isLoading: Bool = false
    var errorMessage: String?
    var currentPage: Int = 1
    var hasMorePages: Bool = true
    var totalCount: Int = 0

    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol = NetworkService.shared) {
        self.networkService = networkService
    }

    func fetchPopularRepositories(page: Int = 1) async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        do {
            let response = try await networkService.searchPopularRepositories(page: page, perPage: 30)

            if page == 1 {
                repositories = response.items
            } else {
                repositories.append(contentsOf: response.items)
            }

            currentPage = page
            totalCount = response.totalCount
            hasMorePages = repositories.count < response.totalCount

        } catch let error as NetworkError {
            errorMessage = error.errorMessage
        } catch {
            errorMessage = "An unexpected error occurred"
        }

        isLoading = false
    }

    func loadNextPage() async {
        guard hasMorePages && !isLoading else { return }
        await fetchPopularRepositories(page: currentPage + 1)
    }

    func refresh() async {
        currentPage = 1
        hasMorePages = true
        repositories = []
        await fetchPopularRepositories(page: 1)
    }
}
