import Foundation

/// Provides version information based on Git repository state
class GitVersionInfoProvider {
    
    // Path to the version generation script
    private let scriptPath: String
    
    // Fallback values when Git is not available
    private static let fallbackBuildNumber = "1"
    private static let fallbackVersionString = "1.0.0+unknown"
    private static let fallbackCommitHash = "unknown"
    
    // Cache for version information to avoid repeated script execution
    private var cachedBuildNumber: String?
    private var cachedVersionString: String?
    private var cachedCommitHash: String?
    
    /// Initialize with custom script path (mainly for testing)
    init(scriptPath: String? = nil) {
        if let customPath = scriptPath {
            self.scriptPath = customPath
        } else {
            // Default path relative to the project root
            self.scriptPath = Bundle.main.path(forResource: "generate-version", ofType: "sh") ?? 
                             "\(Bundle.main.bundlePath)/../../scripts/generate-version.sh"
        }
    }
    
    /// Get build number (Git commit count)
    var buildNumber: String {
        if let cached = cachedBuildNumber {
            return cached
        }
        
        let result = executeScript(argument: "build-number")
        cachedBuildNumber = result.isEmpty ? Self.fallbackBuildNumber : result
        return cachedBuildNumber ?? Self.fallbackBuildNumber
    }
    
    /// Get version string (semantic version + commit hash)
    var versionString: String {
        if let cached = cachedVersionString {
            return cached
        }
        
        let result = executeScript(argument: "version-string")
        cachedVersionString = result.isEmpty ? Self.fallbackVersionString : result
        return cachedVersionString ?? Self.fallbackVersionString
    }
    
    /// Get commit hash
    var commitHash: String {
        if let cached = cachedCommitHash {
            return cached
        }
        
        let result = executeScript(argument: "commit-hash")
        cachedCommitHash = result.isEmpty ? Self.fallbackCommitHash : result
        return cachedCommitHash ?? Self.fallbackCommitHash
    }
    
    /// Execute the version generation script with given argument
    private func executeScript(argument: String) -> String {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.arguments = [scriptPath, argument]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe() // Suppress error output
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            
            return output ?? ""
        } catch {
            return ""
        }
    }
    
    /// Clear cached values (useful for testing)
    func clearCache() {
        cachedBuildNumber = nil
        cachedVersionString = nil
        cachedCommitHash = nil
    }
}