@testable import App
import Foundation
import Vapor

final class MockWeatherService: WeatherServiceProtocol {
    // Mock data
    private let mockCurrentWeather: [String: WeatherResponse] = [
        "London": WeatherResponse(
            location: "London",
            temperature: 18.5,
            description: "Partly Cloudy",
            humidity: 65,
            windSpeed: 12.5
        ),
        "Paris": WeatherResponse(
            location: "Paris",
            temperature: 22.0,
            description: "Sunny",
            humidity: 55,
            windSpeed: 8.2
        ),
        "Tokyo": WeatherResponse(
            location: "Tokyo",
            temperature: 25.5,
            description: "Clear Sky",
            humidity: 70,
            windSpeed: 5.5
        ),
        "Berlin": WeatherResponse(
            location: "Berlin",
            temperature: 15.5,
            description: "Light Rain",
            humidity: 75,
            windSpeed: 15.0
        )
    ]
    
    private let mockForecasts: [String: [DailyForecast]] = [
        "London": [
            DailyForecast(date: Date(), maxTemperature: 20.0, minTemperature: 15.0, description: "Partly Cloudy", humidity: 65, windSpeed: 12.5),
            DailyForecast(date: Date().addingTimeInterval(86400), maxTemperature: 22.0, minTemperature: 16.0, description: "Sunny", humidity: 60, windSpeed: 10.0),
            DailyForecast(date: Date().addingTimeInterval(172800), maxTemperature: 19.0, minTemperature: 14.0, description: "Light Rain", humidity: 75, windSpeed: 15.0),
            DailyForecast(date: Date().addingTimeInterval(259200), maxTemperature: 21.0, minTemperature: 15.0, description: "Cloudy", humidity: 70, windSpeed: 11.0),
            DailyForecast(date: Date().addingTimeInterval(345600), maxTemperature: 23.0, minTemperature: 17.0, description: "Sunny", humidity: 55, windSpeed: 9.0)
        ],
        "Paris": [
            DailyForecast(date: Date(), maxTemperature: 24.0, minTemperature: 18.0, description: "Sunny", humidity: 55, windSpeed: 8.2),
            DailyForecast(date: Date().addingTimeInterval(86400), maxTemperature: 25.0, minTemperature: 19.0, description: "Clear Sky", humidity: 50, windSpeed: 7.5),
            DailyForecast(date: Date().addingTimeInterval(172800), maxTemperature: 23.0, minTemperature: 17.0, description: "Partly Cloudy", humidity: 60, windSpeed: 9.0)
        ]
    ]
    
    func getCurrentWeather(for location: String) async throws -> WeatherResponse {
        guard !location.isEmpty else {
            throw Abort(.badRequest, reason: "Location cannot be empty")
        }
        
        if let weather = mockCurrentWeather[location] {
            return weather
        }
        
        throw Abort(.badRequest, reason: "Location not found")
    }
    
    func getForecast(for location: String, days: Int = 5) async throws -> WeatherForecast {
        guard !location.isEmpty else {
            throw Abort(.badRequest, reason: "Location cannot be empty")
        }
        
        guard days > 0 && days <= 5 else {
            throw Abort(.badRequest, reason: "Days must be between 1 and 5")
        }
        
        if let forecasts = mockForecasts[location] {
            let limitedForecasts = Array(forecasts.prefix(days))
            return WeatherForecast(location: location, forecast: limitedForecasts)
        }
        
        throw Abort(.badRequest, reason: "Location not found")
    }
} 