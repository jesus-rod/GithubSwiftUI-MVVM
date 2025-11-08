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
            ZStack {
                if viewModel.isLoading {
                    ProgressView("Loading")
                } else if let user = viewModel.user {
                    UserView(user: user)
                } else {
                    UserPlaceHolderView()
                }

            }
        }
        .navigationTitle("GitHub User")
        .task {
            await viewModel.fetchUser("jesus-rod")
        }
        .refreshable {
            await viewModel.fetchUser("octocat")
        }
    }

}

struct UserView: View {
    let user: GHUser
    var body: some View {
        VStack {
            AsyncImage(url: URL(string: user.avatarUrl)) { image in
                image.resizable()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 120, height: 120)
            .clipShape(Circle())

            VStack(spacing: 8) {
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
            .padding()
            Spacer()
        }
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
