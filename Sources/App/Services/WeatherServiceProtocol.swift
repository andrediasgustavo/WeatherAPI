import Vapor
import Foundation

protocol WeatherServiceProtocol: Sendable {
    func getCurrentWeather(for location: String) async throws -> WeatherResponse
    func getForecast(for location: String, days: Int) async throws -> WeatherForecast
} 