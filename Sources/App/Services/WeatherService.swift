import Vapor
import Foundation

@MainActor
final class WeatherService: WeatherServiceProtocol, Sendable {
    private static var _shared: WeatherService?
    
    static func shared() throws -> WeatherService {
        if let existing = _shared {
            return existing
        }
        let service = try WeatherService()
        _shared = service
        return service
    }
    
    private let baseURL = Config.openWeatherBaseUrl
    private let apiKey: String
    
    private init() throws {
        self.apiKey = try Config.getApiKey()
    }
    
    static func initialize() throws -> WeatherService {
        return try WeatherService()
    }
    
    // Real weather data from OpenWeatherMap API
    func getCurrentWeather(for location: String) async throws -> WeatherResponse {
        // Validate location
        guard !location.isEmpty else {
            throw Abort(.badRequest, reason: "Location cannot be empty")
        }
        
        // URL encode the location
        guard let encodedLocation = location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw Abort(.badRequest, reason: "Invalid location format")
        }
        
        // Construct the API URL
        let url = "\(baseURL)/weather?q=\(encodedLocation)&appid=\(apiKey)&units=metric"
        print("Requesting URL:", url) // Debug print
        
        guard let apiURL = URL(string: url) else {
            throw Abort(.internalServerError, reason: "Invalid API URL")
        }
        
        // Make the API request
        let (data, response) = try await URLSession.shared.data(from: apiURL)
        
        // Check for valid response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw Abort(.badRequest, reason: "Invalid response from weather API")
        }
        
        if httpResponse.statusCode != 200 {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                throw Abort(.badRequest, reason: "Weather API error: \(errorJson)")
            }
            throw Abort(.badRequest, reason: "Weather API error: \(httpResponse.statusCode)")
        }
        
        // Parse the JSON response
        struct OpenWeatherResponse: Decodable {
            let main: Main
            let weather: [Weather]
            let wind: Wind
            let name: String
            
            struct Main: Decodable {
                let temp: Double
                let humidity: Int
            }
            
            struct Weather: Decodable {
                let description: String
            }
            
            struct Wind: Decodable {
                let speed: Double
            }
        }
        
        let decoder = JSONDecoder()
        let weatherData = try decoder.decode(OpenWeatherResponse.self, from: data)
        
        return WeatherResponse(
            location: weatherData.name,
            temperature: weatherData.main.temp,
            description: weatherData.weather.first?.description.capitalized ?? "Unknown",
            humidity: weatherData.main.humidity,
            windSpeed: weatherData.wind.speed
        )
    }
    
    func getForecast(for location: String, days: Int = 5) async throws -> WeatherForecast {
        // Validate input
        guard !location.isEmpty else {
            throw Abort(.badRequest, reason: "Location cannot be empty")
        }
        
        guard days > 0 && days <= 5 else {
            throw Abort(.badRequest, reason: "Days must be between 1 and 5")
        }
        
        // URL encode the location
        guard let encodedLocation = location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw Abort(.badRequest, reason: "Invalid location format")
        }
        
        // Construct the API URL for 5-day forecast
        let url = "\(baseURL)/forecast?q=\(encodedLocation)&appid=\(apiKey)&units=metric"
        
        guard let apiURL = URL(string: url) else {
            throw Abort(.internalServerError, reason: "Invalid API URL")
        }
        
        // Make the API request
        let (data, response) = try await URLSession.shared.data(from: apiURL)
        
        // Check for valid response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw Abort(.badRequest, reason: "Invalid response from weather API")
        }
        
        if httpResponse.statusCode != 200 {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                throw Abort(.badRequest, reason: "Weather API error: \(errorJson)")
            }
            throw Abort(.badRequest, reason: "Weather API error: \(httpResponse.statusCode)")
        }
        
        // Parse the JSON response
        struct OpenWeatherForecast: Decodable {
            let list: [ForecastItem]
            let city: City
            
            struct ForecastItem: Decodable {
                let dt: TimeInterval
                let main: Main
                let weather: [Weather]
                let wind: Wind
            }
            
            struct Main: Decodable {
                let temp_max: Double
                let temp_min: Double
                let humidity: Int
            }
            
            struct Weather: Decodable {
                let description: String
            }
            
            struct Wind: Decodable {
                let speed: Double
            }
            
            struct City: Decodable {
                let name: String
            }
        }
        
        let decoder = JSONDecoder()
        let forecastData = try decoder.decode(OpenWeatherForecast.self, from: data)
        
        // Process the forecast data (OpenWeatherMap returns data in 3-hour intervals)
        var dailyForecasts: [DailyForecast] = []
        var processedDays = Set<String>()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for item in forecastData.list {
            let date = Date(timeIntervalSince1970: item.dt)
            let dateString = dateFormatter.string(from: date)
            
            // Only take one forecast per day
            if !processedDays.contains(dateString) && dailyForecasts.count < days {
                processedDays.insert(dateString)
                
                let forecast = DailyForecast(
                    date: date,
                    maxTemperature: item.main.temp_max,
                    minTemperature: item.main.temp_min,
                    description: item.weather.first?.description.capitalized ?? "Unknown",
                    humidity: item.main.humidity,
                    windSpeed: item.wind.speed
                )
                dailyForecasts.append(forecast)
            }
        }
        
        return WeatherForecast(
            location: forecastData.city.name,
            forecast: dailyForecasts
        )
    }
} 