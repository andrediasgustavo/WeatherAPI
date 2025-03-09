# Weather API Documentation

A Swift-based weather API service that provides current weather and forecast data using the OpenWeatherMap API.

## Table of Contents
- [Setup](#setup)
- [Security](#security)
- [API Endpoints](#api-endpoints)
- [Response Models](#response-models)
- [iOS Integration](#ios-integration)
- [Error Handling](#error-handling)

## Setup

### Prerequisites
- Swift 6.0 or later
- macOS 13.0 or later
- Vapor framework
- OpenWeatherMap API key

### Installation
1. Clone the repository
2. Navigate to the project directory
3. Set up your OpenWeatherMap API key:
   ```bash
   export OPENWEATHER_API_KEY=your_api_key_here
   ```
   Or create a `.env` file in the project root:
   ```
   OPENWEATHER_API_KEY=your_api_key_here
   ```
4. Run the following commands:
   ```bash
   cd WeatherAPI
   swift build
   swift run
   ```

The server will start at `http://127.0.0.1:8081`

## Security

### API Key Protection
The OpenWeatherMap API key is handled securely through environment variables. Never commit your API key to version control. Instead:

1. For development:
   - Use environment variables
   - Use a `.env` file (add it to .gitignore)
   - Use your OS's secret management system

2. For production:
   - Use environment variables
   - Use a secure secret management service
   - Consider using a key rotation strategy

3. For iOS apps:
   - Deploy the API to a secure server
   - Implement proper authentication
   - Use HTTPS for all communications
   - Consider implementing rate limiting
   - Add API key proxying through your server

### Environment Variables
Required environment variables:
- `OPENWEATHER_API_KEY`: Your OpenWeatherMap API key

You can set these using:
```bash
export OPENWEATHER_API_KEY=your_api_key_here
```

Or create a `.env` file:
```
OPENWEATHER_API_KEY=your_api_key_here
```

### Production Deployment
When deploying to production:
1. Use HTTPS
2. Implement authentication
3. Use secure headers
4. Implement rate limiting
5. Use a production-grade secret management solution

## API Endpoints

### 1. Get Current Weather
Retrieves the current weather for a specified location.

**Endpoint:** `GET /weather/current/:location`

**Parameters:**
- `location` (path parameter): Name of the city (e.g., "London", "Paris", "Tokyo")

**Example Request:**
```http
GET http://127.0.0.1:8081/weather/current/London
```

**Example Response:**
```json
{
    "location": "London",
    "temperature": 18.5,
    "description": "Partly Cloudy",
    "humidity": 65,
    "windSpeed": 12.5
}
```

### 2. Get Weather Forecast
Retrieves a weather forecast for a specified location and number of days.

**Endpoint:** `GET /weather/forecast/:location`

**Parameters:**
- `location` (path parameter): Name of the city
- `days` (query parameter, optional): Number of days for forecast (1-5, default: 5)

**Example Request:**
```http
GET http://127.0.0.1:8081/weather/forecast/Paris?days=3
```

**Example Response:**
```json
{
    "location": "Paris",
    "forecast": [
        {
            "date": "2025-03-08T12:00:00Z",
            "maxTemperature": 24.0,
            "minTemperature": 18.0,
            "description": "Sunny",
            "humidity": 55,
            "windSpeed": 8.2
        },
        {
            "date": "2025-03-09T12:00:00Z",
            "maxTemperature": 25.0,
            "minTemperature": 19.0,
            "description": "Clear Sky",
            "humidity": 50,
            "windSpeed": 7.5
        },
        {
            "date": "2025-03-10T12:00:00Z",
            "maxTemperature": 23.0,
            "minTemperature": 17.0,
            "description": "Partly Cloudy",
            "humidity": 60,
            "windSpeed": 9.0
        }
    ]
}
```

## Response Models

### WeatherResponse
```swift
struct WeatherResponse: Content {
    let location: String
    let temperature: Double
    let description: String
    let humidity: Int
    let windSpeed: Double
}
```

### WeatherForecast
```swift
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
```

## iOS Integration

Here's how to integrate the Weather API into your iOS app:

### 1. Create API Client

```swift
import Foundation

class WeatherAPIClient {
    private let baseURL = "http://127.0.0.1:8081"
    
    func getCurrentWeather(for location: String) async throws -> WeatherResponse {
        guard let url = URL(string: "\(baseURL)/weather/current/\(location)") else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(WeatherResponse.self, from: data)
    }
    
    func getForecast(for location: String, days: Int = 5) async throws -> WeatherForecast {
        guard let url = URL(string: "\(baseURL)/weather/forecast/\(location)?days=\(days)") else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(WeatherForecast.self, from: data)
    }
}
```

### 2. Use in SwiftUI View

```swift
import SwiftUI

struct WeatherView: View {
    @State private var weather: WeatherResponse?
    @State private var errorMessage: String?
    private let apiClient = WeatherAPIClient()
    
    var body: some View {
        VStack {
            if let weather = weather {
                Text(weather.location)
                    .font(.title)
                Text("\(Int(weather.temperature))°C")
                    .font(.largeTitle)
                Text(weather.description)
                    .font(.headline)
                HStack {
                    Text("Humidity: \(weather.humidity)%")
                    Text("Wind: \(Int(weather.windSpeed)) m/s")
                }
            } else if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
        }
        .task {
            do {
                weather = try await apiClient.getCurrentWeather(for: "London")
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
```

### 3. Network Security

For iOS 9 and later, you need to configure App Transport Security (ATS) in your Info.plist to allow HTTP connections to localhost. Add the following to your Info.plist:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
</dict>
```

## Error Handling

The API returns standard HTTP status codes:

- 200: Success
- 400: Bad Request (invalid location, invalid days parameter)
- 500: Internal Server Error

Error responses follow this format:
```json
{
    "error": true,
    "reason": "Error message description"
}
```

Common error scenarios:
- Empty location
- Invalid location name
- Days parameter out of range (1-5)
- API connection issues

## Rate Limiting

The API uses the standard OpenWeatherMap rate limiting:
- 60 calls per minute for the free tier
- Consider implementing caching in your iOS app for frequent requests 