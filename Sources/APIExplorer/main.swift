import Foundation
import KasetCore

@main
struct APIExplorer {
    static func main() async {
        let logger = DiagnosticsLogger()
        let explorer = APIExplorerService(client: YTMusicClient(logger: logger), logger: logger)

        do {
            try await explorer.run(arguments: CommandLine.arguments)
        } catch {
            logger.log(.error, "\(error)")
            Foundation.exit(1)
        }
    }
}

struct APIExplorerService {
    private let client: YTMusicClient
    private let logger: DiagnosticsLogger

    init(client: YTMusicClient, logger: DiagnosticsLogger) {
        self.client = client
        self.logger = logger
    }

    func run(arguments: [String]) async throws {
        let command = ExplorerCommand(arguments: arguments)

        switch command.action {
        case .help:
            self.printUsage()
        case .auth:
            try await self.showAuthStatus(verbose: command.verbose)
        case .list:
            await self.showKnownEndpoints(verbose: command.verbose)
        case let .browse(endpoint):
            try await self.browse(endpoint: endpoint, verbose: command.verbose)
        }
    }

    private func printUsage() {
        self.logger.log(.info, "Usage: swift run api-explorer <auth|list|browse <endpoint>> [-v]")
    }

    private func showAuthStatus(verbose: Bool) async throws {
        let status = try await self.client.authStatus()
        self.logger.log(.info, "Authenticated: \(status.isAuthenticated)")
        self.logger.log(.info, "Account hint: \(status.accountEmailHint)")

        if verbose {
            self.logger.log(.debug, "Verbose auth check completed using API path /music/get_auth")
        }
    }

    private func showKnownEndpoints(verbose: Bool) async {
        let endpoints = await self.client.listEndpoints()
        self.logger.log(.info, "Known endpoints: \(endpoints.joined(separator: ", "))")

        if verbose {
            self.logger.log(.debug, "Loaded \(endpoints.count) endpoints from local endpoint catalog")
        }
    }

    private func browse(endpoint: String, verbose: Bool) async throws {
        do {
            let response = try await self.client.browse(endpoint: endpoint)
            self.logger.log(.info, "Endpoint: \(response.endpoint)")
            self.logger.log(.info, "Title: \(response.title)")
            self.logger.log(.info, "Items: \(response.itemCount)")

            if verbose {
                self.logger.log(.debug, "Verbose browse metadata source=YTMusicClient endpoint=\(endpoint)")
            }
        } catch {
            if case YTMusicError.endpointNotFound = error {
                self.logger.log(.warning, "Unknown endpoint: \(endpoint)")
                let known = await self.client.listEndpoints().joined(separator: ", ")
                self.logger.log(.info, "Try one of: \(known)")
                return
            }

            throw error
        }
    }
}

private struct ExplorerCommand {
    enum Action {
        case help
        case auth
        case list
        case browse(endpoint: String)
    }

    let action: Action
    let verbose: Bool

    init(arguments: [String]) {
        let parsed = Array(arguments.dropFirst())
        self.verbose = parsed.contains("-v") || parsed.contains("--verbose")
        let remaining = parsed.filter { $0 != "-v" && $0 != "--verbose" }

        guard let first = remaining.first else {
            self.action = .help
            return
        }

        switch first {
        case "auth":
            self.action = .auth
        case "list":
            self.action = .list
        case "browse":
            if remaining.count > 1 {
                self.action = .browse(endpoint: remaining[1])
            } else {
                self.action = .help
            }
        default:
            self.action = .help
        }
    }
}
