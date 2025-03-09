import Foundation
import Vapor

enum Configuration {
    static func loadEnvironment() {
        // Try to load from environment variable first
        if Environment.get("OPENWEATHER_API_KEY") != nil {
            print("✅ Found OpenWeather API Key in environment")
        }
        
        // Log rate limit configuration
        if let maxRequests = Environment.get("RATE_LIMIT_MAX_REQUESTS") {
            print("✅ Rate limit max requests: \(maxRequests)")
        } else {
            print("⚠️ Using default rate limit max requests")
        }
        
        if let windowMinutes = Environment.get("RATE_LIMIT_WINDOW_MINUTES") {
            print("✅ Rate limit window minutes: \(windowMinutes)")
        } else {
            print("⚠️ Using default rate limit window")
        }
        
        // If not found, try to load from .env file
        let envPath = DirectoryConfiguration.detect().workingDirectory + ".env"
        do {
            let envContents = try String(contentsOfFile: envPath, encoding: .utf8)
            print("✅ Found .env file")
            
            // Parse and set environment variables
            let envVars = parse(envFile: envContents)
            for (key, value) in envVars {
                setenv(key, value, 1)
            }
        } catch {
            print("⚠️ Could not load .env file: \(error)")
        }
        
        #if DEBUG
        // Fallback for development only
        if Environment.get("OPENWEATHER_API_KEY") == nil {
            print("❌ Error: OpenWeather API key not found")
            print("Please set OPENWEATHER_API_KEY in environment or .env file")
            fatalError("Missing required environment variable: OPENWEATHER_API_KEY")
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
