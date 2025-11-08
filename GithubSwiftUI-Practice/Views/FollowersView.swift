//
//  FollowersView.swift
//  GithubSwiftUI-Practice
//
//  Created by jesus on 08.11.25.
//


import SwiftUI

struct FollowersView: View {
    let username: String
    @State var viewModel: FollowersViewModel

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading followers...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.errorMessage {
                ContentUnavailableView(
                    "Error Loading Followers",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else if viewModel.followers.isEmpty {
                ContentUnavailableView(
                    "No Followers",
                    systemImage: "person.2",
                    description: Text("This user has no followers")
                )
            } else {
                List {
                    ForEach(viewModel.followers) { follower in
                        FollowerRowView(user: follower)
                    }
                }
            }
        }
        .navigationTitle("Followers")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.fetchFollowers(for: username)
        }
    }
}

struct FollowerRowView: View {
    let user: GHUser
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: user.avatarUrl)) { image in
                image.resizable()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                if let name = user.name {
                    Text(name)
                        .font(.headline)
                }
                Text("@\(user.login)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
