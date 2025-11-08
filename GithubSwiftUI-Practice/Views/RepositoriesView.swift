//
//  RepositoriesView.swift
//  GithubSwiftUI-Practice
//
//  Created by jesus on 08.11.25.
//

import SwiftUI

struct RepositoriesView: View {
    let username: String
    @State var viewModel: ReposViewModel

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading repositories...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.errorMessage {
                ContentUnavailableView(
                    "Error Loading Repositories",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else if viewModel.repos.isEmpty {
                ContentUnavailableView(
                    "No Repositories",
                    systemImage: "folder",
                    description: Text("This user has no public repositories")
                )
            } else {
                List {
                    ForEach(viewModel.repos) { item in
                        Text(item.name)
                    }
                }
            }
        }
        .navigationTitle("Repositories")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.fetchRepos(for: username)
        }
    }

}
