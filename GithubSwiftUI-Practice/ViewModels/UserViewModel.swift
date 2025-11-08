//
//  UserViewModel.swift
//  GithubSwiftUI-Practice
//
//  Created by jesus on 08.11.25.
//

import Foundation
import Combine

@MainActor
class UserViewModel: ObservableObject {
    
    @Published var user: GHUser?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }
    
    func fetchUser(_ username: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            user = try await networkService.fetchUser(username: username)
        } catch let error as NetworkError{
            errorMessage = error.errorMessage
        } catch {
            errorMessage = "An unexpected error ocurred"
        }
        
        isLoading = false
    }
    
    func clearError() {
        errorMessage = nil
    }
}


