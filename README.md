# GitHub SwiftUI MVVM

A modern iOS application demonstrating best practices in SwiftUI architecture, network programming, and comprehensive testing strategies.

## Overview

This project showcases a production-grade GitHub user browser built with SwiftUI, featuring clean architecture, robust error handling, and enterprise-level testing patterns. It demonstrates how to build scalable, maintainable iOS applications with proper separation of concerns and comprehensive test coverage.

## Architecture

### MVVM (Model-View-ViewModel) Pattern

The app follows the MVVM architectural pattern, which provides clear separation between UI logic and business logic:

```
┌─────────────┐         ┌──────────────┐         ┌─────────────┐
│    Views    │ ──────> │  ViewModels  │ ──────> │   Models    │
│  (SwiftUI)  │         │  (@Observable)│         │  (Structs)  │
└─────────────┘         └──────────────┘         └─────────────┘
                               │
                               │
                        ┌──────▼──────┐
                        │  Services   │
                        │  (Network)  │
                        └─────────────┘
```

#### Models
Pure data structures conforming to `Codable` and `Identifiable`:
- `GHUser` - GitHub user information
- `GHRepo` - Repository details
- `SearchResponse<T>` - Generic search results wrapper

#### ViewModels
Observable classes managing state and business logic using the `@Observable` macro:
- `UserViewModel` - User profile management
- `ReposViewModel` - Repository list management
- `FollowersViewModel` - Followers list management
- `PopularReposViewModel` - Popular repositories with pagination

ViewModels handle:
- Network request orchestration
- Loading state management
- Error handling and user-friendly messages
- Data transformation for UI consumption

#### Views
SwiftUI views that observe ViewModels and render UI:
- `ContentView` - Main user profile screen
- `RepositoriesView` - Repository list
- `FollowersView` - Followers list
- `PopularRepositoriesListView` - Trending repositories

### Dependency Injection

The app uses protocol-based dependency injection for testability:

```swift
protocol NetworkServiceProtocol: Sendable {
    func fetchUser(username: String) async throws -> GHUser
    func fetchRepos(for username: String) async throws -> [GHRepo]
    func fetchFollowers(for username: String) async throws -> [GHUser]
    func searchPopularRepositories(page: Int, perPage: Int) async throws -> SearchResponse<GHRepo>
}
```

ViewModels accept the protocol, allowing real or mock implementations:

```swift
class UserViewModel {
    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol = NetworkService.shared) {
        self.networkService = networkService
    }
}
```

### Actor-Based Networking

The `NetworkService` is implemented as an actor to ensure thread-safe network operations:

```swift
actor NetworkService: NetworkServiceProtocol {
    static let shared = NetworkService()

    private func fetch<T: Decodable>(endpoint: String) async throws -> T {
        // Generic fetch implementation
    }
}
```

**Benefits:**
- Automatic isolation of mutable state
- No data races or thread safety issues
- Clean async/await API
- Safe concurrent access from multiple ViewModels

### Error Handling

Comprehensive error handling with custom error types:

```swift
enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case invalidData
    case networkError(Error)
    case notFound
    case forbidden
    case rateLimitExceeded

    var errorMessage: String {
        // User-friendly messages
    }
}
```

ViewModels translate technical errors into user-friendly messages displayed in the UI using `ContentUnavailableView`.

## Testing Architecture

### Test Pyramid

The project implements a comprehensive testing strategy covering multiple layers:

```
        ┌──────────────────┐
        │   UI Tests       │  (Not included - would use XCUITest)
        └──────────────────┘
       ┌────────────────────┐
       │ Integration Tests  │  (URLProtocol mocking)
       └────────────────────┘
    ┌───────────────────────────┐
    │     Unit Tests            │  (ViewModel & Model tests)
    └───────────────────────────┘
 ┌─────────────────────────────────┐
 │  Performance & Memory Tests     │  (Leak detection, benchmarks)
 └─────────────────────────────────┘
```

### Testing Patterns

#### 1. Test Fixtures Pattern

Centralized test data builders eliminate duplication:

```swift
enum TestFixtures {
    static func makeUser(
        id: Int = 1,
        login: String = "testuser",
        // ... other parameters with defaults
    ) -> GHUser {
        // Create configured user
    }

    static func makeUserArray(count: Int = 3) -> [GHUser]
    static func makeRepo(...) -> GHRepo
    static func makeSearchResponse<T>(...) -> SearchResponse<T>
}
```

**Benefits:**
- Consistent test data across test suites
- Easy customization via parameters
- Reduced test code duplication
- Clear test intent

#### 2. Configurable Mock Pattern

Advanced mock network service with behavior configuration:

```swift
actor ConfigurableMockNetworkService: NetworkServiceProtocol {
    // Response configuration
    var userResponse: Result<GHUser, Error>?
    var responseDelay: Duration = .zero
    var shouldFailNextCall = false

    // Call tracking
    private(set) var fetchUserCallCount = 0
    private(set) var lastFetchedUsername: String?

    // Convenience methods
    func simulateNetworkError()
    func simulateRateLimitError()
    func setResponseDelay(_ delay: Duration)
}
```

**Benefits:**
- Test different scenarios (success, failure, delays)
- Verify call counts and parameters
- Simulate edge cases (rate limiting, timeouts)
- No need for multiple mock implementations

#### 3. Given-When-Then Structure

Tests follow the Given-When-Then pattern for clarity:

```swift
func test_userViewModel_fetchesUserSuccessfully() async {
    // Given: A ViewModel with a mock service
    let mockService = ConfigurableMockNetworkService()
    let viewModel = UserViewModel(networkService: mockService)

    // When: Fetching a user
    await viewModel.fetchUser("testuser")

    // Then: User is loaded and no error
    XCTAssertNotNil(viewModel.user)
    XCTAssertNil(viewModel.errorMessage)
    XCTAssertFalse(viewModel.isLoading)
}
```

#### 4. Actor Testing Pattern

Testing actor isolation and concurrent access:

```swift
func test_networkService_canHandleConcurrentRequests() async throws {
    let service = mockService!

    // When: Multiple concurrent requests
    async let user1 = service.fetchUser(username: "user1")
    async let user2 = service.fetchUser(username: "user2")
    async let repos = service.fetchRepos(for: "user3")

    // Then: All complete without issues
    let _ = try await user1
    let _ = try await user2
    let _ = try await repos

    XCTAssertEqual(await service.fetchUserCallCount, 2)
}
```

#### 5. Loading State Testing

Verifying asynchronous state transitions:

```swift
func test_userViewModel_setsLoadingStateCorrectly() async {
    // Given: Delayed response
    await mockService.setResponseDelay(.milliseconds(200))
    let viewModel = UserViewModel(networkService: mockService)

    // When: Starting fetch
    let fetchTask = Task {
        await viewModel.fetchUser("test")
    }

    try? await Task.sleep(for: .milliseconds(10))

    // Then: Loading during operation
    XCTAssertTrue(viewModel.isLoading)

    await fetchTask.value

    // Then: Not loading after completion
    XCTAssertFalse(viewModel.isLoading)
}
```

#### 6. Memory Leak Testing

Using weak references to verify proper deallocation:

```swift
func test_userViewModel_doesNotLeakMemory() async {
    weak var weakViewModel: UserViewModel?

    // Create and use ViewModel in local scope
    await withCheckedContinuation { continuation in
        Task { @MainActor in
            autoreleasepool {
                let viewModel = UserViewModel(networkService: mockService)
                weakViewModel = viewModel
                await viewModel.fetchUser("test")
            }
            continuation.resume()
        }
    }

    try? await Task.sleep(for: .milliseconds(100))

    // ViewModel should be deallocated
    XCTAssertNil(weakViewModel)
}
```

#### 7. Integration Testing with URLProtocol

Testing actual network layer with mocked responses:

```swift
class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            fatalError("Request handler is not set")
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
}
```

#### 8. Performance Testing

Establishing performance baselines:

```swift
func testPerformance_userViewModel_fetchUser() {
    let viewModel = UserViewModel(networkService: mockService)

    measure {
        let expectation = expectation(description: "Fetch user")
        Task { @MainActor in
            await viewModel.fetchUser("testuser")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5.0)
    }
}
```

### Test Coverage Areas

#### Unit Tests
- ViewModel state management
- Error handling and recovery
- Data transformation
- Model decoding (JSON to Swift)
- Edge cases (empty data, special characters, unicode)

#### Concurrency Tests
- Race condition handling
- Concurrent request management
- Loading state synchronization
- Actor isolation verification

#### Integration Tests
- URL construction
- HTTP status code handling
- Response validation
- Network error scenarios
- Timeout handling

#### Error Handling Tests
- All error type coverage
- Error message formatting
- Multiple consecutive errors
- Error recovery flows
- Error state consistency

#### Performance Tests
- Fetch operation benchmarks
- Decoding performance
- Large dataset handling
- Pagination performance

#### Memory Tests
- Leak detection
- Resource cleanup
- Stress testing
- Concurrent ViewModel management

## Key Technologies

### Swift Concurrency
- `async/await` for asynchronous operations
- `actor` for thread-safe networking
- `@MainActor` for UI updates
- `Task` for structured concurrency

### SwiftUI
- `@Observable` macro for reactive ViewModels
- `NavigationStack` for navigation
- `AsyncImage` for image loading
- `ContentUnavailableView` for empty/error states
- `refreshable` modifier for pull-to-refresh

### Modern Swift Features
- Protocol-oriented design
- Generic programming
- Result type for error handling
- Property wrappers
- Snake case to camel case conversion

## Project Structure

```
GithubSwiftUI-MVVM/
├── GithubSwiftUI-Practice/
│   ├── Models/
│   │   ├── GHUser.swift
│   │   ├── GHRepo.swift
│   │   └── SearchResponse.swift
│   ├── ViewModels/
│   │   ├── UserViewModel.swift
│   │   ├── ReposViewModel.swift
│   │   ├── FollowersViewModel.swift
│   │   └── PopularReposViewModel.swift
│   ├── Views/
│   │   ├── ContentView.swift
│   │   ├── RepositoriesView.swift
│   │   ├── FollowersView.swift
│   │   └── PopularRepositoriesListView.swift
│   └── Services/
│       └── NetworkService.swift
└── GithubSwiftUI-PracticeTests/
    ├── TestFixtures.swift
    ├── ConfigurableMockNetworkService.swift
    ├── MockNetworkService.swift
    ├── NetworkServiceTests.swift
    ├── GithubSwiftUI_PracticeTests.swift
    ├── ViewModelAdvancedTests.swift
    ├── ConcurrencyAndLoadingTests.swift
    ├── NetworkServiceIntegrationTests.swift
    ├── ErrorHandlingTests.swift
    └── PerformanceAndMemoryTests.swift
```

## Features

- 🔍 Search GitHub users
- 👤 View user profiles with avatar, bio, and stats
- 📦 Browse user repositories
- 👥 View user followers
- ⭐ Discover popular repositories with pagination
- 🔄 Pull-to-refresh functionality
- ⚠️ Comprehensive error handling
- 📱 Modern iOS design patterns

## Testing Best Practices Demonstrated

1. **Test Isolation** - Each test is independent and can run in any order
2. **Fast Tests** - Mock network calls for speed
3. **Readable Tests** - Given-When-Then structure
4. **Maintainable Tests** - Fixtures reduce duplication
5. **Comprehensive Coverage** - Happy paths, error cases, edge cases
6. **Async Testing** - Proper handling of Swift concurrency
7. **Performance Baselines** - Track performance regressions
8. **Memory Safety** - Verify no retain cycles or leaks
9. **Integration Testing** - Test real network layer with mocked responses
10. **Actor Testing** - Verify thread safety and concurrent access

## Running Tests

```bash
# Run all tests
xcodebuild test -scheme GithubSwiftUI-Practice -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test suite
xcodebuild test -scheme GithubSwiftUI-Practice -only-testing:GithubSwiftUI-PracticeTests/ViewModelAdvancedTests

# Run with coverage
xcodebuild test -scheme GithubSwiftUI-Practice -enableCodeCoverage YES
```

## Learning Outcomes

This project demonstrates:

- Building scalable iOS apps with MVVM
- Implementing thread-safe networking with actors
- Writing comprehensive test suites
- Using dependency injection for testability
- Handling errors gracefully
- Managing asynchronous state
- Following iOS best practices
- Creating maintainable, production-ready code

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 6.0+

## License

Educational project for demonstrating iOS development best practices.
