//
//  Config.swift
//  RaceAnalytics
//
//  Epic 5 - IRA-26: Claude API Configuration
//  Secure API key storage and app configuration
//

import Foundation

/// Application configuration and API keys
/// 
/// IMPORTANT: Add Config.swift to .gitignore
/// Never commit API keys to version control
enum Config {
    
    // MARK: - Claude API Configuration
    
    /// Claude API Key from Anthropic Console
    /// Get your key at: https://console.anthropic.com/
    static let claudeAPIKey: String = {
        // Priority 1: Try to load from Keychain
        if let keychainKey = KeychainManager.shared.getAPIKey() {
            return keychainKey
        }
        
        // Priority 2: Load from environment variable (for development)
        if let envKey = ProcessInfo.processInfo.environment["CLAUDE_API_KEY"] {
            return envKey
        }
        
        // Priority 3: Hardcoded key (for initial setup only)
        // TODO: Replace with your actual API key or use Keychain
        return "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"
    }()
    
    /// Claude API Base URL
    static let claudeAPIBaseURL = "https://api.anthropic.com/v1"
    
    /// Claude Model to use
    static let claudeModel = "claude-sonnet-4-20250514"
    
    /// API Version header
    static let claudeAPIVersion = "2023-06-01"
    
    // MARK: - AI Coaching Settings
    
    /// Maximum tokens for AI responses
    static let maxTokens = 2048
    
    /// Temperature for AI creativity (0.0-1.0)
    /// Lower = more focused, Higher = more creative
    static let temperature = 0.7
    
    /// System prompt for karting coach persona
    static let coachingSystemPrompt = """
    You are an expert karting coach specializing in IAME X30 Junior racing.
    Your student is Troy, a 14-year-old driver racing an FA 2025 chassis.
    
    Analyze telemetry data and provide:
    - Clear, actionable feedback
    - Specific corner-by-corner advice
    - Braking point optimization
    - Apex trajectory improvements
    - Speed and RPM management tips
    
    Keep responses concise, encouraging, and age-appropriate.
    Focus on 1-2 key improvements per analysis.
    """
    
    // MARK: - App Settings
    
    /// Enable debug logging
    static let debugMode = true
    
    /// Cache AI responses for offline viewing
    static let cacheAIResponses = true
    
    /// Maximum cached responses
    static let maxCachedResponses = 50
}

// MARK: - Keychain Manager

/// Secure storage for API keys using iOS Keychain
class KeychainManager {
    static let shared = KeychainManager()
    
    private let service = "com.raceanalytics.apikeys"
    private let account = "claude-api-key"
    
    private init() {}
    
    /// Store API key securely in Keychain
    func saveAPIKey(_ key: String) -> Bool {
        let data = key.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        
        // Delete any existing key first
        SecItemDelete(query as CFDictionary)
        
        // Add new key
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Retrieve API key from Keychain
    func getAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return key
    }
    
    /// Delete API key from Keychain
    func deleteAPIKey() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
}

// MARK: - API Key Validation

extension Config {
    /// Check if Claude API key is configured
    static var isClaudeAPIConfigured: Bool {
        return !claudeAPIKey.isEmpty && 
               !claudeAPIKey.contains("YOUR_API_KEY_HERE")
    }
    
    /// Validate API key format (basic check)
    static func validateAPIKey(_ key: String) -> Bool {
        // Claude API keys start with "sk-ant-api"
        return key.hasPrefix("sk-ant-api") && key.count > 20
    }
}
