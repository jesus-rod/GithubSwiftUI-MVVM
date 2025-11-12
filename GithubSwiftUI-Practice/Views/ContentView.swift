//
//  ContentView.swift
//  GithubSwiftUI-Practice
//
//  Created by jesus on 08.11.25.
//

import SwiftUI

struct ContentView: View {

    @State private var viewModel = UserViewModel()
    
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
    @State private var navigateToRepos = false
    @State private var navigateToFollowers = false
    @State private var popularReposViewModel = PopularReposViewModel()

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
                StatView(title: "Repos", value: user.publicRepos ?? 0) {
                    navigateToRepos = true
                }
                StatView(title: "Followers", value: user.followers ?? 0) {
                    navigateToFollowers = true
                }
                StatView(title: "Following", value: user.following ?? 0) {
                    print("Following tapped - could show following list")
                }
            }
            .padding(.top, 8)

            // Popular Repositories Section
            Divider()
                .padding(.vertical, 8)

            PopularRepositoriesListView(viewModel: popularReposViewModel)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationDestination(isPresented: $navigateToRepos) {
            let reposVm = ReposViewModel()
            RepositoriesView(username: user.login, viewModel: reposVm)
        }
        .navigationDestination(isPresented: $navigateToFollowers) {
            let followersVm = FollowersViewModel()
            FollowersView(username: user.login, viewModel: followersVm)
        }
    }
}

// MARK: - Stat View Component
struct StatView: View {
    let title: String
    let value: Int
    let action: (() -> Void)?
    
    init(title: String, value: Int, action: (() -> Void)? = nil) {
        self.title = title
        self.value = value
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title2)
                .bold()
            HStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                }
            }
            .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            action?()
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
