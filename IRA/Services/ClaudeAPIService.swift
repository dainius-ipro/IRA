//
//  ClaudeAPIService.swift
//  RaceAnalytics
//
//  Epic 5 - IRA-26: Claude API Integration
//

import Foundation

class ClaudeAPIService {
    static let shared = ClaudeAPIService()
    
    private let baseURL = Config.claudeAPIBaseURL
    private let apiKey = Config.claudeAPIKey
    private let model = Config.claudeModel
    
    private init() {}
    
    // MARK: - API Models
    
    struct Message: Codable {
        let role: String
        let content: String
    }
    
    struct APIRequest: Codable {
        let model: String
        let max_tokens: Int
        let messages: [Message]
        let system: String?
        let temperature: Double?
    }
    
    struct APIResponse: Codable {
        let id: String
        let type: String
        let role: String
        let content: [ContentBlock]
        let model: String
        let stop_reason: String?
        let usage: Usage?
        
        struct ContentBlock: Codable {
            let type: String
            let text: String?
        }
        
        struct Usage: Codable {
            let input_tokens: Int
            let output_tokens: Int
        }
    }
    
    struct APIError: Codable {
        let type: String
        let error: ErrorDetail
        
        struct ErrorDetail: Codable {
            let type: String
            let message: String
        }
    }
    
    // MARK: - Public Methods
    
    func sendMessage(
        _ prompt: String,
        systemPrompt: String? = Config.coachingSystemPrompt,
        conversationHistory: [Message] = []
    ) async throws -> String {
        
        guard Config.isClaudeAPIConfigured else {
            throw APIServiceError.apiKeyNotConfigured
        }
        
        var messages = conversationHistory
        messages.append(Message(role: "user", content: prompt))
        
        let request = APIRequest(
            model: model,
            max_tokens: Config.maxTokens,
            messages: messages,
            system: systemPrompt,
            temperature: Config.temperature
        )
        
        let response = try await makeRequest(request)
        
        guard let text = response.content.first?.text else {
            throw APIServiceError.emptyResponse
        }
        
        return text
    }
    
    func analyzeTelemetry(
        _ telemetryData: String,
        analysisType: AnalysisType
    ) async throws -> CoachingInsight {
        
        let prompt = buildAnalysisPrompt(telemetryData: telemetryData, type: analysisType)
        let response = try await sendMessage(prompt)
        
        return CoachingInsight(
            type: analysisType,
            text: response,
            timestamp: Date(),
            telemetrySnapshot: telemetryData
        )
    }
    
    // MARK: - Private Methods
    
    private func makeRequest(_ request: APIRequest) async throws -> APIResponse {
        guard let url = URL(string: "\(baseURL)/messages") else {
            throw APIServiceError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue(Config.claudeAPIVersion, forHTTPHeaderField: "anthropic-version")
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        if Config.debugMode {
            print("🤖 Claude API Request:")
            print("Model: \(request.model)")
            print("Messages: \(request.messages.count)")
            print("Max Tokens: \(request.max_tokens)")
        }
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIServiceError.invalidResponse
        }
        
        if Config.debugMode {
            print("📡 Claude API Response: \(httpResponse.statusCode)")
        }
        
        if httpResponse.statusCode != 200 {
            if let apiError = try? JSONDecoder().decode(APIError.self, from: data) {
                throw APIServiceError.apiError(apiError.error.message)
            } else {
                throw APIServiceError.httpError(httpResponse.statusCode)
            }
        }
        
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(APIResponse.self, from: data)
        
        if Config.debugMode, let usage = apiResponse.usage {
            print("📊 Token Usage - Input: \(usage.input_tokens), Output: \(usage.output_tokens)")
        }
        
        return apiResponse
    }
    
    private func buildAnalysisPrompt(telemetryData: String, type: AnalysisType) -> String {
        let basePrompt = """
        Analyze this karting telemetry data and provide coaching insights.
        
        Focus Area: \(type.rawValue)
        
        Telemetry Data:
        \(telemetryData)
        
        Provide:
        1. Key observation
        2. Specific improvement suggestion
        3. Expected lap time gain
        
        Keep response concise (3-4 sentences).
        """
        
        return basePrompt
    }
}

// MARK: - Error Types

enum APIServiceError: LocalizedError {
    case apiKeyNotConfigured
    case invalidURL
    case invalidResponse
    case emptyResponse
    case httpError(Int)
    case apiError(String)
    case encodingError
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .apiKeyNotConfigured:
            return "Claude API key is not configured. Please add your API key in Config.swift"
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .emptyResponse:
            return "Empty response from Claude API"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .apiError(let message):
            return "API error: \(message)"
        case .encodingError:
            return "Failed to encode request"
        case .decodingError:
            return "Failed to decode response"
        }
    }
}

// MARK: - Response Caching

extension ClaudeAPIService {
    class ResponseCache {
        static let shared = ResponseCache()
        
        private let cacheKey = "cached_coaching_insights"
        private let maxCacheSize = Config.maxCachedResponses
        
        func save(_ insight: CoachingInsight) {
            var cached = loadAll()
            cached.append(insight)
            
            if cached.count > maxCacheSize {
                cached = Array(cached.suffix(maxCacheSize))
            }
            
            if let data = try? JSONEncoder().encode(cached) {
                UserDefaults.standard.set(data, forKey: cacheKey)
            }
        }
        
        func loadAll() -> [CoachingInsight] {
            guard let data = UserDefaults.standard.data(forKey: cacheKey),
                  let cached = try? JSONDecoder().decode([CoachingInsight].self, from: data) else {
                return []
            }
            return cached
        }
        
        func clear() {
            UserDefaults.standard.removeObject(forKey: cacheKey)
        }
    }
}