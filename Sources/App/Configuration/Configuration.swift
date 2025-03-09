import Foundation
import Vapor

enum Configuration {
    static func loadEnvironment() {
        // Try to load from environment variable first
        if let existingKey = Environment.get("OPENWEATHER_API_KEY") {
            return
        }
        
        // If not found, try to load from .env file
        let workingDirectory = DirectoryConfiguration.detect().workingDirectory
        let envPath = workingDirectory + ".env"
        
        if FileManager.default.fileExists(atPath: envPath) {
            do {
                let envContents = try String(contentsOfFile: envPath, encoding: .utf8)
                let envVars = parse(envFile: envContents)
                if let apiKey = envVars["OPENWEATHER_API_KEY"] {
                    setenv("OPENWEATHER_API_KEY", apiKey, 1)
                }
            } catch {
                print("Warning: Could not load .env file")
            }
        }
        
        #if DEBUG
        // Fallback for development only
        if Environment.get("OPENWEATHER_API_KEY") == nil {
            setenv("OPENWEATHER_API_KEY", "ed05c6ebd3140ff1e3e666a7c664ff75", 1)
            print("Warning: Using default API key. Set OPENWEATHER_API_KEY in environment or .env file")
        }
        #endif
    }
    
    private static func parse(envFile contents: String) -> [String: String] {
        var envVars: [String: String] = [:]
        
        contents.components(separatedBy: .newlines).forEach { line in
            let parts = line.split(separator: "=", maxSplits: 1)
            if parts.count == 2 {
                let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
                let value = String(parts[1]).trimmingCharacters(in: .whitespaces)
                envVars[key] = value
            }
        }
        
        return envVars
    }
} 
