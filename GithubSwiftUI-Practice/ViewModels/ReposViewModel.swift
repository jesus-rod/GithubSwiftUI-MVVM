//
//  ReposViewModel.swift
//  GithubSwiftUI-Practice
//
//  Created by jesus on 08.11.25.
//

import Combine

@MainActor
class ReposViewModel: ObservableObject {
    
    @Published var repos: [GHRepo]?
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }
    
    func fetchRepos(for username: String) async {
        
        do {
            repos = try await networkService.fetchRepos(for: username)
        } catch let error as NetworkError {
            print(error.errorMessage)
        } catch {
            print(NetworkError.networkError(error))
        }
        
        
    }
}
