import Vapor
import Foundation

// configures your application
public func configure(_ app: Application) async throws {
    // Ensure working directory is set
    app.directory.workingDirectory = DirectoryConfiguration.detect().workingDirectory
    
    // Load environment configuration
    Configuration.loadEnvironment()
    
    // Set server configuration
    app.http.server.configuration.hostname = "127.0.0.1"
    app.http.server.configuration.port = 8082
    
    // Configure CORS
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .OPTIONS],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith]
    )
    app.middleware.use(CORSMiddleware(configuration: corsConfiguration))
    
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
