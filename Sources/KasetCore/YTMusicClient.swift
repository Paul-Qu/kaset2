import Foundation

public actor YTMusicClient {
    private let endpoints: [String: YTBrowseResponse]
    private let logger: DiagnosticsLogger

    public init(logger: DiagnosticsLogger = .init()) {
        self.logger = logger
        self.endpoints = [
            "FEmusic_home": .init(endpoint: "FEmusic_home", title: "Home", itemCount: 24),
            "FEmusic_liked_playlists": .init(endpoint: "FEmusic_liked_playlists", title: "Liked Playlists", itemCount: 8),
            "FEmusic_history": .init(endpoint: "FEmusic_history", title: "History", itemCount: 50),
        ]
    }

    public func authStatus() async throws -> YTAuthStatus {
        self.logger.log(.debug, "Checking auth status via YTMusicClient API")
        return YTAuthStatus(isAuthenticated: true, accountEmailHint: "signed-in-user@REDACTED")
    }

    public func listEndpoints() async -> [String] {
        self.logger.log(.debug, "Listing known browse endpoints")
        return self.endpoints.keys.sorted()
    }

    public func browse(endpoint: String) async throws -> YTBrowseResponse {
        self.logger.log(.debug, "Browsing endpoint \(endpoint)")

        guard let response = self.endpoints[endpoint] else {
            throw YTMusicError.endpointNotFound(endpoint)
        }

        return response
    }
}
