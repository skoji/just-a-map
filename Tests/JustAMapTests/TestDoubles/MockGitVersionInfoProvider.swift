@testable import JustAMap

class MockGitVersionInfoProvider: GitVersionInfoProvider {
    
    var mockBuildNumber: String = "1"
    var mockVersionString: String = "1.0.0+unknown"
    var mockCommitHash: String = "unknown"
    
    override var buildNumber: String {
        return mockBuildNumber
    }
    
    override var versionString: String {
        return mockVersionString
    }
    
    override var commitHash: String {
        return mockCommitHash
    }
    
    override func clearCache() {
        // Mock implementation - no cache to clear
    }
}