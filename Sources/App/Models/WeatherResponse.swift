import Vapor

struct WeatherResponse: Content {
    let location: String
    let temperature: Double
    let description: String
    let humidity: Int
    let windSpeed: Double
    let timestamp: Date
    
    init(location: String, temperature: Double, description: String, humidity: Int, windSpeed: Double) {
        self.location = location
        self.temperature = temperature
        self.description = description
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.timestamp = Date()
    }
}

struct WeatherForecast: Content {
    let location: String
    let forecast: [DailyForecast]
}

struct DailyForecast: Content {
    let date: Date
    let maxTemperature: Double
    let minTemperature: Double
    let description: String
    let humidity: Int
    let windSpeed: Double
} 