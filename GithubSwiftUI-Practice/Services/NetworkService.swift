//
//  NetworkService.swift
//  GithubSwiftUI-Practice
//
//  Created by jesus on 08.11.25.
//


import Foundation

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case invalidData
    case networkError(Error)
    
    var errorMessage: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid server response"
        case .invalidData:
            return "Invalid data"
        case .networkError(let error):
            return error.localizedDescription
            
        }
    }
}

protocol NetworkServiceProtocol {
    func fetchUser(username: String) async throws -> GHUser
    func fetchRepos(for username: String) async throws -> [GHRepo]
    func fetchFollowers(for username: String) async throws -> [GHUser]
}

class NetworkService: NetworkServiceProtocol {
    
    static let shared = NetworkService()
    
    private let decoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    
    private init() {}
    
    func fetchUser(username: String) async throws -> GHUser {
        let endpoint = "https://api.github.com/users/\(username)"
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let response = response as? HTTPURLResponse,
                  response.statusCode == 200 else {
                throw NetworkError.invalidResponse
            }
            
            let user = try decoder.decode(GHUser.self, from: data)
            return user
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.networkError(error)
        }
    }
    
    func fetchRepos(for username: String) async throws -> [GHRepo] {
        let endpoint = "https://api.github.com/users/\(username)/repos"
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let response = response as? HTTPURLResponse,
                  response.statusCode == 200 else {
                throw NetworkError.invalidResponse
            }
            
            let repos = try decoder.decode([GHRepo].self, from: data)
            return repos
        } catch let error as NetworkError{
            throw error
        } catch {
            throw NetworkError.networkError(error)
        }
        
        
    }
    
    func fetchFollowers(for username: String) async throws -> [GHUser] {
        
        let endpoint = "https://api.github.com/users/\(username)/followers"
        
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let response = response as? HTTPURLResponse,
                  response.statusCode == 200 else {
                throw NetworkError.invalidResponse
            }
            return try decoder.decode([GHUser].self, from: data)
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.networkError(error)
        }
    }
}
