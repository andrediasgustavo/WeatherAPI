import Foundation
import Vapor

enum ConfigError: Error {
    case missingAPIKey
}

struct Config {
    static let openWeatherBaseUrl = "https://api.openweathermap.org/data/2.5"
    
    static func getApiKey() throws -> String {
        guard let apiKey = Environment.get("OPENWEATHER_API_KEY") else {
            throw ConfigError.missingAPIKey
        }
        return apiKey
    }
} 