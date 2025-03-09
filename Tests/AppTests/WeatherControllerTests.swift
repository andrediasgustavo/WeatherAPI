@testable import App
import XCTVapor
import XCTest

final class WeatherControllerTests: XCTestCase {
    var app: Application!
    
    override func setUp() async throws {
        app = Application(.testing)
        try await configure(app)
        
        // Register mock service
        let mockService = MockWeatherService()
        app.routes.get("weather", "current", ":location") { req async throws -> WeatherResponse in
            try await mockService.getCurrentWeather(for: req.parameters.get("location") ?? "")
        }
        app.routes.get("weather", "forecast", ":location") { req async throws -> WeatherForecast in
            try await mockService.getForecast(
                for: req.parameters.get("location") ?? "",
                days: req.query["days"] ?? 5
            )
        }
    }
    
    override func tearDown() {
        app.shutdown()
    }
    
    func testGetCurrentWeather() throws {
        try app.test(.GET, "weather/current/London") { res in
            XCTAssertEqual(res.status, .ok)
            
            let weather = try res.content.decode(WeatherResponse.self)
            XCTAssertEqual(weather.location, "London")
            XCTAssertEqual(weather.temperature, 18.5)
            XCTAssertEqual(weather.description, "Partly Cloudy")
            XCTAssertEqual(weather.humidity, 65)
            XCTAssertEqual(weather.windSpeed, 12.5)
        }
    }
    
    func testGetCurrentWeatherInvalidLocation() throws {
        try app.test(.GET, "weather/current/ThisCityDoesNotExist12345") { res in
            XCTAssertEqual(res.status, .badRequest)
            
            let error = try res.content.decode(ErrorResponse.self)
            XCTAssertTrue(error.error)
            XCTAssertEqual(error.reason, "Location not found")
        }
    }
    
    func testGetForecast() throws {
        try app.test(.GET, "weather/forecast/Paris?days=3") { res in
            XCTAssertEqual(res.status, .ok)
            
            let forecast = try res.content.decode(WeatherForecast.self)
            XCTAssertEqual(forecast.location, "Paris")
            XCTAssertEqual(forecast.forecast.count, 3)
            
            // Test first day forecast
            let firstDay = forecast.forecast[0]
            XCTAssertEqual(firstDay.maxTemperature, 24.0)
            XCTAssertEqual(firstDay.minTemperature, 18.0)
            XCTAssertEqual(firstDay.description, "Sunny")
            XCTAssertEqual(firstDay.humidity, 55)
            XCTAssertEqual(firstDay.windSpeed, 8.2)
        }
    }
    
    func testGetForecastInvalidLocation() throws {
        try app.test(.GET, "weather/forecast/ThisCityDoesNotExist12345") { res in
            XCTAssertEqual(res.status, .badRequest)
            
            let error = try res.content.decode(ErrorResponse.self)
            XCTAssertTrue(error.error)
            XCTAssertEqual(error.reason, "Location not found")
        }
    }
    
    func testGetForecastInvalidDays() throws {
        try app.test(.GET, "weather/forecast/London?days=-1") { res in
            XCTAssertEqual(res.status, .badRequest)
            
            let error = try res.content.decode(ErrorResponse.self)
            XCTAssertTrue(error.error)
            XCTAssertEqual(error.reason, "Days must be between 1 and 5")
        }
    }
}

// Helper struct for error responses
private struct ErrorResponse: Content {
    let error: Bool
    let reason: String
}

extension Application {
    static func make(_ environment: Environment = .testing) async throws -> Application {
        let app = Application(environment)
        try await configure(app)
        return app
    }
} 