import Foundation
import KasetCore

#if canImport(SwiftUI)
import SwiftUI

@main
struct KasetApp: App {
    @State private var viewModel = KasetAppViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: self.viewModel)
                .frame(minWidth: 920, minHeight: 620)
                .task {
                    await self.viewModel.loadInitialData()
                }
        }
        .windowResizability(.contentSize)

        Settings {
            SettingsView(viewModel: self.viewModel)
                .frame(width: 420)
                .padding()
        }
    }
}

@MainActor
@Observable
final class KasetAppViewModel {
    private let client: YTMusicClient
    private let logger: DiagnosticsLogger

    var isLoading = false
    var authStatus = YTAuthStatus(isAuthenticated: false, accountEmailHint: "not signed in")
    var endpoints: [String] = []
    var selectedEndpoint: String?
    var browseResult: YTBrowseResponse?
    var statusMessage = "Ready"

    init(client: YTMusicClient = YTMusicClient(), logger: DiagnosticsLogger = DiagnosticsLogger()) {
        self.client = client
        self.logger = logger
    }

    func loadInitialData() async {
        self.isLoading = true
        defer { self.isLoading = false }

        do {
            self.authStatus = try await self.client.authStatus()
            self.endpoints = await self.client.listEndpoints()
            self.selectedEndpoint = self.endpoints.first
            self.statusMessage = "Loaded \(self.endpoints.count) endpoints"

            if let endpoint = self.selectedEndpoint {
                try await self.loadBrowse(endpoint: endpoint)
            }
        } catch {
            self.statusMessage = "Failed to load initial data: \(error)"
            self.logger.log(.error, self.statusMessage)
        }
    }

    func loadBrowse(endpoint: String) async throws {
        self.isLoading = true
        defer { self.isLoading = false }

        do {
            self.browseResult = try await self.client.browse(endpoint: endpoint)
            self.selectedEndpoint = endpoint
            self.statusMessage = "Showing \(endpoint)"
        } catch {
            self.statusMessage = "Browse failed for \(endpoint): \(error)"
            self.logger.log(.warning, self.statusMessage)
            throw error
        }
    }
}

struct ContentView: View {
    let viewModel: KasetAppViewModel

    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Kaset")
                    .font(.largeTitle)
                    .fontWeight(.semibold)

                Text("YouTube Music macOS Client")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Divider()

                endpointList

                Spacer(minLength: 0)
            }
            .padding(20)
            .background(.thinMaterial)
        } detail: {
            VStack(alignment: .leading, spacing: 16) {
                AuthStatusCard(authStatus: viewModel.authStatus)

                if let result = viewModel.browseResult {
                    BrowseResultCard(result: result)
                } else {
                    ContentUnavailableView(
                        "No endpoint selected",
                        systemImage: "music.note.list",
                        description: Text("Select an endpoint from the sidebar.")
                    )
                }

                Spacer(minLength: 0)

                HStack {
                    Text(viewModel.statusMessage)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                    if viewModel.isLoading {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
            }
            .padding(24)
            .background(.regularMaterial)
        }
    }

    private var endpointList: some View {
        List(selection: Binding(
            get: { viewModel.selectedEndpoint },
            set: { newValue in
                guard let endpoint = newValue else { return }
                Task {
                    try? await viewModel.loadBrowse(endpoint: endpoint)
                }
            }
        )) {
            ForEach(viewModel.endpoints, id: \.self) { endpoint in
                Label(endpoint, systemImage: "music.note")
                    .tag(Optional(endpoint))
            }
        }
        .listStyle(.sidebar)
    }
}

struct AuthStatusCard: View {
    let authStatus: YTAuthStatus

    var body: some View {
        GroupBox("Authentication") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Status")
                    Spacer(minLength: 0)
                    Text(authStatus.isAuthenticated ? "Signed In" : "Signed Out")
                        .foregroundStyle(authStatus.isAuthenticated ? .green : .secondary)
                }

                HStack {
                    Text("Account")
                    Spacer(minLength: 0)
                    Text(authStatus.accountEmailHint)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
    }
}

struct BrowseResultCard: View {
    let result: YTBrowseResponse

    var body: some View {
        GroupBox("Endpoint") {
            VStack(alignment: .leading, spacing: 8) {
                row(label: "Endpoint", value: result.endpoint)
                row(label: "Title", value: result.title)
                row(label: "Items", value: String(result.itemCount))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
    }

    private func row(label: String, value: String) -> some View {
        HStack {
            Text(label)
            Spacer(minLength: 0)
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

struct SettingsView: View {
    let viewModel: KasetAppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Kaset Settings")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Current endpoint count: \(viewModel.endpoints.count)")
                .foregroundStyle(.secondary)

            Text("This is a macOS SwiftUI shell that uses KasetCore and coexists with api-explorer.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
    }
}

#else

@main
struct KasetAppUnsupportedPlatformMain {
    static func main() {
        let logger = DiagnosticsLogger()
        logger.log(.warning, "KasetApp (SwiftUI) is only available when SwiftUI can be imported.")
        logger.log(.info, "Use api-explorer CLI on this platform.")
    }
}

#endif
