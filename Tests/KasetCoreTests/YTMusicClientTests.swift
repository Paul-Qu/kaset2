import Testing
@testable import KasetCore

struct YTMusicClientTests {
    @Test func listEndpointsReturnsSortedValues() async {
        let client = YTMusicClient()

        let endpoints = await client.listEndpoints()

        #expect(endpoints == ["FEmusic_history", "FEmusic_home", "FEmusic_liked_playlists"])
    }

    @Test func browseThrowsEndpointNotFoundForUnknownEndpoint() async {
        let client = YTMusicClient()

        await #expect(throws: YTMusicError.endpointNotFound("unknown_endpoint")) {
            _ = try await client.browse(endpoint: "unknown_endpoint")
        }
    }
}
