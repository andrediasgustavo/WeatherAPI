import Vapor
import Redis

struct RateLimitError: AbortError {
    var reason: String
    var status: HTTPStatus = .tooManyRequests
}

struct RateLimiterConfig {
    let maxRequests: Int
    let window: Int64
    
    static let `default` = RateLimiterConfig(maxRequests: 60, window: 60)
}

struct RateLimiter: AsyncMiddleware {
    let redis: RedisClient
    let config: RateLimiterConfig
    
    init(redis: RedisClient, config: RateLimiterConfig = .default) {
        self.redis = redis
        self.config = config
    }
    
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        // Get client identifier (IP address or API key)
        let identifier = try getClientIdentifier(request)
        let key = RedisKey("rate_limit:\(identifier)")
        
        // Check current request count
        let count = try await getCurrentCount(for: key)
        
        if count >= config.maxRequests {
            throw RateLimitError(reason: "Rate limit exceeded. Try again later.")
        }
        
        // Increment the counter
        try await incrementCounter(for: key)
        
        // Add rate limit headers
        let response = try await next.respond(to: request)
        response.headers.add(name: "X-RateLimit-Limit", value: "\(config.maxRequests)")
        response.headers.add(name: "X-RateLimit-Remaining", value: "\(config.maxRequests - count - 1)")
        
        return response
    }
    
    private func getClientIdentifier(_ request: Request) throws -> String {
        // First try to get API key from headers
        if let apiKey = request.headers.first(name: "X-API-Key") {
            return apiKey
        }
        
        // Fallback to IP address
        guard let ip = request.remoteAddress?.hostname else {
            throw RateLimitError(reason: "Could not identify client")
        }
        return ip
    }
    
    private func getCurrentCount(for key: RedisKey) async throws -> Int {
        let value = try await redis.get(key, as: String.self).get()
        return Int(value ?? "0") ?? 0
    }
    
    private func incrementCounter(for key: RedisKey) async throws {
        _ = try await redis.increment(key).get()
        _ = try await redis.expire(key, after: .seconds(config.window)).get()
    }
} 