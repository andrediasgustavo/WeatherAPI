@testable import App
import XCTVapor
import XCTest

final class WeatherServiceTests: XCTestCase {
    var app: Application!
    var weatherService: WeatherServiceProtocol!
    
    override func setUp() async throws {
        app = try await Application.make(.testing)
        try await configure(app)
        weatherService = MockWeatherService()
    }
    
    override func tearDown() {
        app.shutdown()
    }
    
    // MARK: - Current Weather Tests
    
    func testGetCurrentWeatherSuccess() async throws {
        // Given
        let location = "London"
        
        // When
        let weather = try await weatherService.getCurrentWeather(for: location)
        
        // Then
        XCTAssertEqual(weather.location, "London")
        XCTAssertEqual(weather.temperature, 18.5)
        XCTAssertEqual(weather.description, "Partly Cloudy")
        XCTAssertEqual(weather.humidity, 65)
        XCTAssertEqual(weather.windSpeed, 12.5)
    }
    
    func testGetCurrentWeatherInvalidLocation() async throws {
        // Given
        let invalidLocation = "ThisCityDoesNotExist12345"
        
        // When/Then
        do {
            _ = try await weatherService.getCurrentWeather(for: invalidLocation)
            XCTFail("Expected error for invalid location")
        } catch {
            XCTAssertTrue(error is Abort)
            if let abort = error as? Abort {
                XCTAssertEqual(abort.status.code, 400)
                XCTAssertEqual(abort.reason, "Location not found")
            }
        }
    }
    
    func testGetCurrentWeatherEmptyLocation() async throws {
        // Given
        let emptyLocation = ""
        
        // When/Then
        do {
            _ = try await weatherService.getCurrentWeather(for: emptyLocation)
            XCTFail("Expected error for empty location")
        } catch {
            XCTAssertTrue(error is Abort)
            if let abort = error as? Abort {
                XCTAssertEqual(abort.status.code, 400)
                XCTAssertEqual(abort.reason, "Location cannot be empty")
            }
        }
    }
    
    // MARK: - Forecast Tests
    
    func testGetForecastSuccess() async throws {
        // Given
        let location = "Paris"
        let days = 3
        
        // When
        let forecast = try await weatherService.getForecast(for: location, days: days)
        
        // Then
        XCTAssertEqual(forecast.location, "Paris")
        XCTAssertEqual(forecast.forecast.count, days)
        
        // Test first day forecast
        let firstDay = forecast.forecast[0]
        XCTAssertEqual(firstDay.maxTemperature, 24.0)
        XCTAssertEqual(firstDay.minTemperature, 18.0)
        XCTAssertEqual(firstDay.description, "Sunny")
        XCTAssertEqual(firstDay.humidity, 55)
        XCTAssertEqual(firstDay.windSpeed, 8.2)
    }
    
    func testGetForecastInvalidDays() async throws {
        // Given
        let location = "London"
        let invalidDays = -1
        
        // When/Then
        do {
            _ = try await weatherService.getForecast(for: location, days: invalidDays)
            XCTFail("Expected error for invalid days")
        } catch {
            XCTAssertTrue(error is Abort)
            if let abort = error as? Abort {
                XCTAssertEqual(abort.status.code, 400)
                XCTAssertEqual(abort.reason, "Days must be between 1 and 5")
            }
        }
    }
    
    func testGetForecastInvalidLocation() async throws {
        // Given
        let invalidLocation = "ThisCityDoesNotExist12345"
        
        // When/Then
        do {
            _ = try await weatherService.getForecast(for: invalidLocation, days: 5)
            XCTFail("Expected error for invalid location")
        } catch {
            XCTAssertTrue(error is Abort)
            if let abort = error as? Abort {
                XCTAssertEqual(abort.status.code, 400)
                XCTAssertEqual(abort.reason, "Location not found")
            }
        }
    }
    
    // MARK: - Response Format Tests
    
    func testWeatherResponseFormat() async throws {
        // Given
        let location = "Tokyo"
        
        // When
        let weather = try await weatherService.getCurrentWeather(for: location)
        
        // Then
        // Test JSON encoding/decoding
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let jsonData = try encoder.encode(weather)
        let decodedWeather = try decoder.decode(WeatherResponse.self, from: jsonData)
        
        XCTAssertEqual(weather.location, decodedWeather.location)
        XCTAssertEqual(weather.temperature, decodedWeather.temperature)
        XCTAssertEqual(weather.description, decodedWeather.description)
        XCTAssertEqual(weather.humidity, decodedWeather.humidity)
        XCTAssertEqual(weather.windSpeed, decodedWeather.windSpeed)
    }
    
    func testForecastResponseFormat() async throws {
        // Given
        let location = "London"
        let days = 5
        
        // When
        let forecast = try await weatherService.getForecast(for: location, days: days)
        
        // Then
        // Test JSON encoding/decoding
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let jsonData = try encoder.encode(forecast)
        let decodedForecast = try decoder.decode(WeatherForecast.self, from: jsonData)
        
        XCTAssertEqual(forecast.location, decodedForecast.location)
        XCTAssertEqual(forecast.forecast.count, decodedForecast.forecast.count)
        
        // Compare first forecast day
        let firstOriginal = forecast.forecast[0]
        let firstDecoded = decodedForecast.forecast[0]
        
        XCTAssertEqual(firstOriginal.maxTemperature, firstDecoded.maxTemperature)
        XCTAssertEqual(firstOriginal.minTemperature, firstDecoded.minTemperature)
        XCTAssertEqual(firstOriginal.description, firstDecoded.description)
        XCTAssertEqual(firstOriginal.humidity, firstDecoded.humidity)
        XCTAssertEqual(firstOriginal.windSpeed, firstDecoded.windSpeed)
    }
} 