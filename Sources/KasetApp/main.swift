import Foundation
import KasetCore

#if canImport(SwiftUI)
import SwiftUI

@main
struct KasetApp: App {
    @State private var viewModel = KasetAppViewModel()

    var body: some Scene {
        WindowGroup {
            KasetRootView(viewModel: self.viewModel)
                .frame(minWidth: 1180, minHeight: 760)
                .task {
                    await self.viewModel.loadInitialData()
                }
        }

        Settings {
            SettingsView(viewModel: self.viewModel)
                .frame(width: 440)
                .padding()
        }
    }
}

@MainActor
@Observable
final class KasetAppViewModel {
    struct NavigationItem: Identifiable, Hashable {
        enum Group: String {
            case main = "Main"
            case discover = "Discover"
            case library = "Library"
        }

        let id: String
        let title: String
        let icon: String
        let group: Group
    }

    struct TrackCard: Identifiable, Hashable {
        let id: UUID = .init()
        let title: String
        let subtitle: String
        let accent: Color
    }

    struct PlaylistCard: Identifiable, Hashable {
        let id: UUID = .init()
        let title: String
        let subtitle: String
        let accent: Color
    }

    private let client: YTMusicClient
    private let logger: DiagnosticsLogger

    var isLoading = false
    var authStatus = YTAuthStatus(isAuthenticated: false, accountEmailHint: "not signed in")
    var endpoints: [String] = []
    var selectedEndpoint: String?
    var browseResult: YTBrowseResponse?
    var statusMessage = "Ready"

    var searchText = ""
    var selectedNavigationID = "home"

    let navigationItems: [NavigationItem] = [
        .init(id: "home", title: "Home", icon: "house", group: .main),
        .init(id: "explore", title: "Explore", icon: "globe", group: .discover),
        .init(id: "charts", title: "Charts", icon: "chart.line.uptrend.xyaxis", group: .discover),
        .init(id: "moods", title: "Moods & Genres", icon: "music.note", group: .discover),
        .init(id: "new", title: "New Releases", icon: "sparkles", group: .discover),
        .init(id: "liked", title: "Liked Music", icon: "heart.fill", group: .library),
        .init(id: "playlists", title: "Playlists", icon: "music.note.list", group: .library),
    ]

    var quickPicks: [TrackCard] = []
    var featuredPlaylists: [PlaylistCard] = []
    var biggestHits: [PlaylistCard] = []

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

            self.quickPicks = [
                .init(title: "I Want To Break Free", subtitle: "Queen, 1B plays", accent: .orange),
                .init(title: "Golden", subtitle: "HUNTR/X, EJAE", accent: .yellow),
                .init(title: "Geççek", subtitle: "Tarkan, 110M plays", accent: .blue),
                .init(title: "Remember The Time", subtitle: "Michael Jackson, 828M plays", accent: .purple),
                .init(title: "Cruel Summer", subtitle: "Taylor Swift, 607M plays", accent: .pink),
            ]

            self.featuredPlaylists = [
                .init(title: "Pop's Biggest Hits", subtitle: "Updated daily", accent: .pink),
                .init(title: "Christmas Coffeehouse", subtitle: "Smooth classics", accent: .brown),
                .init(title: "Turkish Acoustic Classics", subtitle: "Acoustic gems", accent: .orange),
                .init(title: "Relaxing 80s Rock", subtitle: "Retro energy", accent: .blue),
                .init(title: "Fresh Feel-good Morning", subtitle: "Wake up mix", accent: .mint),
            ]

            self.biggestHits = [
                .init(title: "Hip-Hop Gaming Hits", subtitle: "Power-up tracks", accent: .indigo),
                .init(title: "Turkish Rap Hits 2024", subtitle: "Charts now", accent: .cyan),
                .init(title: "Arabesk Hits 2024", subtitle: "Top vocals", accent: .teal),
                .init(title: "Today's R&B", subtitle: "Modern mood", accent: .gray),
                .init(title: "Türkçe Rock", subtitle: "Indie selection", accent: .green),
            ]

            if let endpoint = self.selectedEndpoint {
                try await self.loadBrowse(endpoint: endpoint)
            }

            self.statusMessage = "Loaded Home feed"
        } catch {
            self.statusMessage = "Failed to load data: \(error)"
            self.logger.log(.error, self.statusMessage)
        }
    }

    func loadBrowse(endpoint: String) async throws {
        self.browseResult = try await self.client.browse(endpoint: endpoint)
        self.selectedEndpoint = endpoint
    }

    var groupedNavigation: [(NavigationItem.Group, [NavigationItem])] {
        let groups: [NavigationItem.Group] = [.main, .discover, .library]
        return groups.map { group in
            let items = self.navigationItems.filter { $0.group == group }
            return (group, items)
        }
    }
}

struct KasetRootView: View {
    let viewModel: KasetAppViewModel

    var body: some View {
        ZStack {
            LinearGradient(colors: [.black, .black.opacity(0.9)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    SidebarView(viewModel: self.viewModel)
                        .frame(width: 250)

                    HomeContentView(viewModel: self.viewModel)
                }

                MiniPlayerBar(viewModel: self.viewModel)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 14)
            }
            .padding(12)
        }
    }
}

struct SidebarView: View {
    let viewModel: KasetAppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search", text: Binding(
                    get: { self.viewModel.searchText },
                    set: { self.viewModel.searchText = $0 }
                ))
                .textFieldStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            ForEach(self.viewModel.groupedNavigation, id: \.0.rawValue) { group, items in
                VStack(alignment: .leading, spacing: 6) {
                    if group != .main {
                        Text(group.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                    }

                    ForEach(items) { item in
                        Button {
                            self.viewModel.selectedNavigationID = item.id
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: item.icon)
                                Text(item.title)
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(self.viewModel.selectedNavigationID == item.id ? Color.white : Color.primary)
                        .background(self.viewModel.selectedNavigationID == item.id ? Color.red.opacity(0.85) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
            }

            Spacer(minLength: 0)

            GroupBox("Account") {
                VStack(alignment: .leading, spacing: 6) {
                    Text(self.viewModel.authStatus.isAuthenticated ? "Signed In" : "Signed Out")
                        .fontWeight(.semibold)
                    Text(self.viewModel.authStatus.accountEmailHint)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct HomeContentView: View {
    let viewModel: KasetAppViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("Home")
                        .font(.title)
                        .fontWeight(.bold)
                    Spacer(minLength: 0)
                    endpointBadge
                }

                sectionTitle("Quick picks")
                horizontalTracks(self.viewModel.quickPicks)

                sectionTitle("Featured playlists for you")
                horizontalPlaylists(self.viewModel.featuredPlaylists)

                sectionTitle("Today's biggest hits")
                horizontalPlaylists(self.viewModel.biggestHits)
            }
            .padding(22)
        }
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.leading, 12)
    }

    private var endpointBadge: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
            Text(self.viewModel.browseResult?.endpoint ?? "No endpoint")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.title3)
            .fontWeight(.semibold)
    }

    private func horizontalTracks(_ tracks: [KasetAppViewModel.TrackCard]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(tracks) { track in
                    VStack(alignment: .leading, spacing: 10) {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [track.accent.opacity(0.9), track.accent.opacity(0.35)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 190, height: 190)
                            .overlay(alignment: .bottomLeading) {
                                Image(systemName: "music.note")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.85))
                                    .padding(14)
                            }

                        Text(track.title)
                            .font(.headline)
                            .lineLimit(1)
                        Text(track.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .frame(width: 190, alignment: .leading)
                }
            }
        }
    }

    private func horizontalPlaylists(_ playlists: [KasetAppViewModel.PlaylistCard]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(playlists) { playlist in
                    VStack(alignment: .leading, spacing: 10) {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [playlist.accent.opacity(0.8), .black.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 190, height: 190)
                            .overlay(alignment: .topLeading) {
                                Circle()
                                    .fill(.white.opacity(0.4))
                                    .frame(width: 14, height: 14)
                                    .padding(10)
                            }

                        Text(playlist.title)
                            .font(.headline)
                            .lineLimit(1)
                        Text(playlist.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .frame(width: 190, alignment: .leading)
                }
            }
        }
    }
}

struct MiniPlayerBar: View {
    let viewModel: KasetAppViewModel

    var body: some View {
        HStack(spacing: 18) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.purple.opacity(0.7))
                    .frame(width: 42, height: 42)
                VStack(alignment: .leading, spacing: 2) {
                    Text(self.viewModel.quickPicks.first?.title ?? "Not Playing")
                        .font(.headline)
                    Text(self.viewModel.quickPicks.first?.subtitle ?? "-")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)

            HStack(spacing: 14) {
                playerButton("shuffle")
                playerButton("backward.fill")
                playerButton("play.fill", highlighted: true)
                playerButton("forward.fill")
                playerButton("repeat")
            }

            Spacer(minLength: 0)

            HStack(spacing: 10) {
                Image(systemName: "speaker.wave.2.fill")
                Slider(value: .constant(0.65))
                    .frame(width: 120)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func playerButton(_ icon: String, highlighted: Bool = false) -> some View {
        Image(systemName: icon)
            .font(.body.weight(.semibold))
            .frame(width: 30, height: 30)
            .background(highlighted ? .red.opacity(0.85) : .white.opacity(0.12))
            .clipShape(Circle())
    }
}

struct SettingsView: View {
    let viewModel: KasetAppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Kaset Settings")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Endpoint count: \(self.viewModel.endpoints.count)")
                .foregroundStyle(.secondary)
            Text("Selected endpoint: \(self.viewModel.selectedEndpoint ?? "none")")
                .foregroundStyle(.secondary)
            Text("Status: \(self.viewModel.statusMessage)")
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
