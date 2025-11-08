//
//  ContentView.swift
//  GithubSwiftUI-Practice
//
//  Created by jesus on 08.11.25.
//

import SwiftUI

struct ContentView: View {

    @StateObject private var viewModel = UserViewModel(
        networkService: NetworkService.shared
    )
    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.isLoading {
                    ProgressView("Loading")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let user = viewModel.user {
                    UserView(user: user)
                } else {
                    UserPlaceHolderView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .refreshable {
                await viewModel.fetchUser("octocat")
            }
        }
        .task {
            await viewModel.fetchUser("jesus-rod")
        }
    }

}

struct UserView: View {
    let user: GHUser
    var body: some View {
        VStack(spacing: 16) {
            AsyncImage(url: URL(string: user.avatarUrl)) { image in
                image.resizable()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 120, height: 120)
            .clipShape(Circle())

            VStack(spacing: 4) {
                if let name = user.name {
                    Text(name)
                        .font(.title)
                        .bold()
                }
                Text("@\(user.login)")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                if let bio = user.bio {
                    Text(bio)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            // Stats
            HStack(spacing: 40) {
                StatView(title: "Repos", value: user.publicRepos ?? 0)
                StatView(title: "Followers", value: user.followers)
                StatView(title: "Following", value: user.following)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Stat View Component
struct StatView: View {
    let title: String
    let value: Int

    var body: some View {
        VStack {
            Text("\(value)")
                .font(.title2)
                .bold()
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct UserPlaceHolderView: View {
    var body: some View {
        ContentUnavailableView(
            "No User Data",
            systemImage: "person.circle",
            description: Text(
                "Pull to refresh or check your connection"
            )
        )
    }
}

#Preview {
    ContentView()
}
