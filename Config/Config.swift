//
//  Config.swift
//  BalanceApp
//
//  Created by j.zembower on 11/8/25.
//

import Foundation

struct Config {
    enum APIProvider: String {
        case openai = "openai"
        case abacus = "abacus"
        case anthropic = "anthropic"
        case openrouter = "openrouter"
    }
    
    // Get API key from Secrets.plist or environment
    static var llmAPIKey: String {
        // Option 1: From Secrets.plist (RECOMMENDED)
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
           let key = dict["LLM_API_KEY"] as? String {
            return key
        }
        
        // Option 2: From environment variable
        if let key = ProcessInfo.processInfo.environment["LLM_API_KEY"] {
            return key
        }
        
        // Fallback (should not be used in production)
        return ""
    }
    
    static var apiProvider: APIProvider {
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
           let provider = dict["API_PROVIDER"] as? String {
            return APIProvider(rawValue: provider) ?? .openrouter
        }
        return .openrouter
    }
    
    static var llmAPIURL: String {
        switch apiProvider {
        case .openai:
            return "https://api.openai.com/v1/chat/completions"
        case .abacus:
            return "https://api.abacus.ai/v1/chat/completions"
        case .anthropic:
            return "https://api.anthropic.com/v1/messages"
        case .openrouter:
            return "https://openrouter.ai/api/v1/chat/completions"
        }
    }
    
    static var llmModel: String {
        switch apiProvider {
        case .openai:
            return "gpt-4o-mini"
        case .abacus:
            return "gpt-4o-mini"
        case .anthropic:
            return "claude-3-haiku-20240307"
        case .openrouter:
            // Amazon Nova Lite - Best balance of cost and quality
            return "amazon/nova-lite-v1"
            
            // Alternative options (uncomment to switch):
            // return "amazon/nova-micro-v1"  // Even cheaper, faster but less capable
            // return "amazon/nova-pro-v1"    // More expensive but highest quality
        }
    }
    
    // Toggle between real and mock data
    static let useMockData = true // Set to false when ready for real HealthKit
}
