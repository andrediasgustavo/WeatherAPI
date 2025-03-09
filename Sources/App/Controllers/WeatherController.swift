import Vapor

@MainActor
struct WeatherController: RouteCollection {
    let weatherService: WeatherServiceProtocol
    
    init(weatherService: WeatherServiceProtocol? = nil) async throws {
        if let service = weatherService {
            self.weatherService = service
        } else {
            self.weatherService = try WeatherService.shared()
        }
    }
    
    nonisolated func boot(routes: RoutesBuilder) throws {
        let weather = routes.grouped("weather")
        weather.get("current", ":location") { req async throws -> WeatherResponse in
            let controller = try await WeatherController()
            return try await controller.getCurrentWeather(req: req)
        }
        weather.get("forecast", ":location") { req async throws -> WeatherForecast in
            let controller = try await WeatherController()
            return try await controller.getForecast(req: req)
        }
    }
    
    func getCurrentWeather(req: Request) async throws -> WeatherResponse {
        guard let location = req.parameters.get("location") else {
            throw Abort(.badRequest, reason: "Location parameter is required")
        }
        
        return try await weatherService.getCurrentWeather(for: location)
    }
    
    func getForecast(req: Request) async throws -> WeatherForecast {
        guard let location = req.parameters.get("location") else {
            throw Abort(.badRequest, reason: "Location parameter is required")
        }
        
        let days = req.query["days"] ?? 5
        return try await weatherService.getForecast(for: location, days: days)
    }
} 