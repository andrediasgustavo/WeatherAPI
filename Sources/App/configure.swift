import Vapor
import Foundation
import Redis

// configures your application
public func configure(_ app: Application) async throws {
    // Ensure working directory is set
    app.directory.workingDirectory = DirectoryConfiguration.detect().workingDirectory
    
    // Load environment configuration
    Configuration.loadEnvironment()
    
    // Configure Redis
    app.redis.configuration = try RedisConfiguration(hostname: Environment.get("REDIS_HOST") ?? "localhost")
    
    // Get rate limit configuration
    let maxRequests = Environment.get("RATE_LIMIT_MAX_REQUESTS").flatMap(Int.init) ?? 60
    let windowMinutes = Environment.get("RATE_LIMIT_WINDOW_MINUTES").flatMap(Int.init) ?? 1
    
    print("📊 Configuring rate limiter with:")
    print("- Max requests: \(maxRequests)")
    print("- Window minutes: \(windowMinutes)")
    
    // Set up rate limiter
    let rateLimiter = RateLimiter(
        redis: app.redis,
        config: RateLimiterConfig(
            maxRequests: maxRequests,
            window: Int64(windowMinutes) * 60
        )
    )
    
    // Set server configuration
    app.http.server.configuration.hostname = "127.0.0.1"
    app.http.server.configuration.port = 8082
    
    // Configure CORS
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .OPTIONS],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .init("X-API-Key")]
    )
    
    // Add middlewares
    app.middleware.use(CORSMiddleware(configuration: corsConfiguration))
    app.middleware.use(rateLimiter)
    
    // register base routes
    try routes(app)
    
    // register weather controller
    do {
        let controller = try await WeatherController()
        try app.register(collection: controller)
    } catch ConfigError.missingAPIKey {
        app.logger.error("OpenWeather API key not found in environment variables. Please set OPENWEATHER_API_KEY.")
        throw ConfigError.missingAPIKey
    } catch {
        app.logger.error("Failed to initialize WeatherController: \(error)")
        throw error
    }
    
    // Log the server address
    print("Server starting at http://\(app.http.server.configuration.hostname):\(app.http.server.configuration.port)")
}
