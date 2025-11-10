//
//  APIDebugHelper.swift
//  BalanceApp
//
//  Created by j.zembower on 11/8/25.
//


import Foundation

class APIDebugHelper {
    static func testConnection(completion: @escaping (Bool, String) -> Void) {
        let apiKey = Config.llmAPIKey
        let apiURL = Config.llmAPIURL
        let model = Config.llmModel
        
        // Check if API key exists
        guard !apiKey.isEmpty else {
            completion(false, "❌ API key is empty")
            return
        }
        
        // Check if API key format is correct
        guard apiKey.hasPrefix("sk-or-v1-") else {
            completion(false, "❌ API key format incorrect (should start with 'sk-or-v1-')")
            return
        }
        
        // Make a simple test request
        guard let url = URL(string: apiURL) else {
            completion(false, "❌ Invalid API URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("BalanceApp", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("BalanceApp/1.0", forHTTPHeaderField: "X-Title")
        request.timeoutInterval = 10
        
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "user", "content": "Say 'API connection successful' if you can read this."]
            ],
            "max_tokens": 20
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false, "❌ Network error: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(false, "❌ Invalid response")
                return
            }
            
            if (200...299).contains(httpResponse.statusCode) {
                completion(true, "✅ API connected successfully!\nModel: \(model)\nProvider: OpenRouter")
            } else {
                var errorMsg = "❌ API error (Status: \(httpResponse.statusCode))"
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = json["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    errorMsg += "\n\(message)"
                }
                completion(false, errorMsg)
            }
        }.resume()
    }
}