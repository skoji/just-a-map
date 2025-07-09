import XCTest
@testable import JustAMap

class GitVersionInfoTests: XCTestCase {
    
    func testGitVersionInfoProviderInitialization() {
        // Test that GitVersionInfoProvider can be initialized
        let provider = GitVersionInfoProvider()
        XCTAssertNotNil(provider)
    }
    
    func testBuildNumberIsNumeric() {
        // Test that build number is always numeric
        let provider = GitVersionInfoProvider()
        let buildNumber = provider.buildNumber
        
        XCTAssertFalse(buildNumber.isEmpty, "Build number should not be empty")
        XCTAssertNotNil(Int(buildNumber), "Build number should be a valid integer")
    }
    
    func testVersionStringFormat() {
        // Test that version string follows expected format
        let provider = GitVersionInfoProvider()
        let versionString = provider.versionString
        
        XCTAssertFalse(versionString.isEmpty, "Version string should not be empty")
        XCTAssertTrue(versionString.contains("."), "Version string should contain dots for semantic versioning")
        XCTAssertTrue(versionString.contains("+"), "Version string should contain '+' for commit hash")
    }
    
    func testBuildNumberIsIncreasing() {
        // Test that build number represents an increasing value
        let provider = GitVersionInfoProvider()
        let buildNumber = provider.buildNumber
        
        guard let buildNum = Int(buildNumber) else {
            XCTFail("Build number should be a valid integer")
            return
        }
        
        XCTAssertGreaterThan(buildNum, 0, "Build number should be greater than 0")
    }
    
    func testCommitHashIsPresent() {
        // Test that commit hash is present in version info
        let provider = GitVersionInfoProvider()
        let commitHash = provider.commitHash
        
        XCTAssertFalse(commitHash.isEmpty, "Commit hash should not be empty")
        XCTAssertNotEqual(commitHash, "unknown", "Commit hash should not be 'unknown' in a Git repository")
    }
    
    func testVersionInfoConsistency() {
        // Test that version info is consistent across multiple calls
        let provider = GitVersionInfoProvider()
        
        let buildNumber1 = provider.buildNumber
        let buildNumber2 = provider.buildNumber
        XCTAssertEqual(buildNumber1, buildNumber2, "Build number should be consistent")
        
        let versionString1 = provider.versionString
        let versionString2 = provider.versionString
        XCTAssertEqual(versionString1, versionString2, "Version string should be consistent")
    }
    
    func testFallbackBehavior() {
        // Test fallback behavior when Git is not available
        let provider = GitVersionInfoProvider(scriptPath: "/nonexistent/path")
        
        let buildNumber = provider.buildNumber
        let versionString = provider.versionString
        
        XCTAssertFalse(buildNumber.isEmpty, "Build number should have fallback value")
        XCTAssertFalse(versionString.isEmpty, "Version string should have fallback value")
    }
    
    func testBaseVersionIsPresent() {
        // Test that base version is present in version string
        let provider = GitVersionInfoProvider()
        let versionString = provider.versionString
        
        XCTAssertTrue(versionString.hasPrefix("1.0.0"), "Version string should start with base version")
    }
    
    func testPerformanceOfVersionGeneration() {
        // Test that version generation is performant
        let provider = GitVersionInfoProvider()
        
        measure {
            _ = provider.buildNumber
            _ = provider.versionString
            _ = provider.commitHash
        }
    }
}