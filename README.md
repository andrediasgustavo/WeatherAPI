# Weather API Service

A RESTful weather service built with Vapor that provides current weather and forecast data using the OpenWeather API.

## Features

- Current weather data for any city
- 5-day weather forecast
- Rate limiting with Redis
- API key authentication
- CORS support

## Requirements

- Swift 5.9+
- Redis server
- OpenWeather API key

## Setup

1. Clone the repository
2. Create a `.env` file in the project root with:
```
OPENWEATHER_API_KEY=your_api_key_here
REDIS_HOST=localhost
REDIS_PORT=6379
RATE_LIMIT_MAX_REQUESTS=60
RATE_LIMIT_WINDOW_MINUTES=1
```

3. Start Redis server
4. Run the project:
```bash
swift run
```

The server will start at `http://127.0.0.1:8082`

## API Endpoints

### Current Weather
```
GET /weather/current/{city}
```

**Parameters:**
- `city`: Name of the city (required)

**Headers:**
- `X-API-Key`: Your API key for authentication

**Response:**
```json
{
    "temperature": 20.5,
    "humidity": 65,
    "windSpeed": 5.2,
    "description": "Clear sky",
    "city": "London"
}
```

### Weather Forecast
```
GET /weather/forecast/{city}/{days}
```

**Parameters:**
- `city`: Name of the city (required)
- `days`: Number of days (1-5, required)

**Headers:**
- `X-API-Key`: Your API key for authentication

**Response:**
```json
{
    "city": "London",
    "forecasts": [
        {
            "date": "2024-03-20",
            "temperature": 18.5,
            "humidity": 70,
            "windSpeed": 4.8,
            "description": "Partly cloudy"
        }
        // ... more days
    ]
}
```

## Rate Limiting

The API implements rate limiting using Redis:
- Default: 60 requests per minute per API key
- Configurable via environment variables
- Headers returned:
  - `X-RateLimit-Limit`: Maximum requests allowed
  - `X-RateLimit-Remaining`: Remaining requests in the window

## Error Responses

```json
{
    "error": true,
    "reason": "Error message here"
}
```

Common HTTP status codes:
- 200: Success
- 400: Bad Request (invalid parameters)
- 401: Unauthorized (missing/invalid API key)
- 429: Too Many Requests (rate limit exceeded)
- 500: Internal Server Error

## Development

Built with:
- [Vapor](https://vapor.codes) - Server-side Swift framework
- [Redis](https://redis.io) - For rate limiting
- [OpenWeather API](https://openweathermap.org/api) - Weather data source 