import Foundation

public struct YTAuthStatus: Equatable, Sendable {
    public let isAuthenticated: Bool
    public let accountEmailHint: String

    public init(isAuthenticated: Bool, accountEmailHint: String) {
        self.isAuthenticated = isAuthenticated
        self.accountEmailHint = accountEmailHint
    }
}

public struct YTBrowseResponse: Equatable, Sendable {
    public let endpoint: String
    public let title: String
    public let itemCount: Int

    public init(endpoint: String, title: String, itemCount: Int) {
        self.endpoint = endpoint
        self.title = title
        self.itemCount = itemCount
    }
}
