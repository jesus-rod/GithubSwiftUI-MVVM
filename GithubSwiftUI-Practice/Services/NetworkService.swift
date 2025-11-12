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
    case notFound
    case forbidden
    case rateLimitExceeded

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
        case .notFound:
            return "User or resource not found"
        case .forbidden:
            return "Access forbidden"
        case .rateLimitExceeded:
            return "GitHub API rate limit exceeded. Try again later"
        }
    }
}

protocol NetworkServiceProtocol: Sendable {
    func fetchUser(username: String) async throws -> GHUser
    func fetchRepos(for username: String) async throws -> [GHRepo]
    func fetchFollowers(for username: String) async throws -> [GHUser]
    func searchPopularRepositories(page: Int, perPage: Int) async throws -> SearchResponse<GHRepo>
}

actor NetworkService: NetworkServiceProtocol {

    static let shared = NetworkService()

    private let baseURL = "https://api.github.com"

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    private let session: URLSession

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: configuration)
    }

    // MARK: - Public API

    func fetchUser(username: String) async throws -> GHUser {
        try await fetch(endpoint: "/users/\(username)")
    }

    func fetchRepos(for username: String) async throws -> [GHRepo] {
        try await fetch(endpoint: "/users/\(username)/repos")
    }

    func fetchFollowers(for username: String) async throws -> [GHUser] {
        try await fetch(endpoint: "/users/\(username)/followers")
    }

    func searchPopularRepositories(page: Int = 1, perPage: Int = 30) async throws -> SearchResponse<GHRepo> {
        let query = "stars:>1"
        let endpoint = "/search/repositories?q=\(query)&sort=stars&order=desc&per_page=\(perPage)&page=\(page)"
        return try await fetch(endpoint: endpoint)
    }

    // MARK: - Private Helpers

    private func fetch<T: Decodable>(endpoint: String) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw NetworkError.invalidURL
        }

        do {
            let (data, response) = try await session.data(from: url)
            try validateResponse(response)
            return try decoder.decode(T.self, from: data)
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.networkError(error)
        }
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 404:
            throw NetworkError.notFound
        case 403:
            throw NetworkError.forbidden
        case 429:
            throw NetworkError.rateLimitExceeded
        default:
            throw NetworkError.invalidResponse
        }
    }
}
