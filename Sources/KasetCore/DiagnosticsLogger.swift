import Foundation

public enum DiagnosticsLevel: String, Sendable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
}

public struct DiagnosticsLogger: Sendable {
    public init() {}

    public func log(_ level: DiagnosticsLevel, _ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        Self.write("[\(timestamp)] [\(level.rawValue)] \(message)")
    }

    private static func write(_ message: String) {
        guard let data = "\(message)\n".data(using: .utf8) else {
            return
        }

        FileHandle.standardOutput.write(data)
    }
}
