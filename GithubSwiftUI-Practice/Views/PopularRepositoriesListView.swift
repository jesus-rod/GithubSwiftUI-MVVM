//
//  PopularRepositoriesListView.swift
//  GithubSwiftUI-Practice
//
//  Created by jesus on 08.11.25.
//

import SwiftUI

struct PopularRepositoriesListView: View {
    @State var viewModel: PopularReposViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Popular Repositories")
                .font(.headline)
                .padding(.horizontal)

            if viewModel.repositories.isEmpty && viewModel.isLoading {
                ProgressView("Loading popular repositories...")
                    .frame(maxWidth: .infinity, maxHeight: 200)
            } else if let error = viewModel.errorMessage {
                ContentUnavailableView(
                    "Error Loading Repositories",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
                .frame(height: 200)
            } else if viewModel.repositories.isEmpty {
                ContentUnavailableView(
                    "No Repositories Found",
                    systemImage: "magnifyingglass",
                    description: Text("Unable to load popular repositories")
                )
                .frame(height: 200)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.repositories) { repo in
                            PopularRepoRow(repo: repo)
                                .onAppear {
                                    // Trigger pagination when last item appears
                                    if repo.id == viewModel.repositories.last?.id {
                                        Task {
                                            await viewModel.loadNextPage()
                                        }
                                    }
                                }
                        }

                        // Loading indicator for pagination
                        if viewModel.isLoading && !viewModel.repositories.isEmpty {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding()
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 400)
            }
        }
        .task {
            if viewModel.repositories.isEmpty {
                await viewModel.fetchPopularRepositories()
            }
        }
    }
}

struct PopularRepoRow: View {
    let repo: GHRepo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Repository name
            Text(repo.fullName ?? repo.name)
                .font(.headline)
                .foregroundStyle(.primary)

            // Description
            if let description = repo.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            // Stats row
            HStack(spacing: 16) {
                if let stars = repo.stargazersCount {
                    Label("\(formatCount(stars))", systemImage: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }

                if let forks = repo.forksCount {
                    Label("\(formatCount(forks))", systemImage: "tuningfork")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let language = repo.language {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(languageColor(for: language))
                            .frame(width: 8, height: 8)
                        Text(language)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.1fk", Double(count) / 1000.0)
        }
        return "\(count)"
    }

    private func languageColor(for language: String) -> Color {
        switch language.lowercased() {
        case "swift": return .orange
        case "javascript", "typescript": return .yellow
        case "python": return .blue
        case "java": return .red
        case "go": return .cyan
        case "rust": return .brown
        default: return .gray
        }
    }
}
