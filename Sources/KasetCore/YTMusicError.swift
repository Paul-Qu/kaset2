import Foundation

public enum YTMusicError: Error, Equatable, Sendable {
    case authExpired
    case endpointNotFound(String)
}
