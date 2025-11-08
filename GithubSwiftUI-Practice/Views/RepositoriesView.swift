//
//  RepositoriesView.swift
//  GithubSwiftUI-Practice
//
//  Created by jesus on 08.11.25.
//

import SwiftUI

struct RepositoriesView: View {
    let username: String
    @StateObject var viewModel: ReposViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.repos ?? [], id: \.id) { item in
                Text(item.name)
            }
        }
        .navigationTitle("Repositories")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.fetchRepos(for: username)
        }
    }

}
