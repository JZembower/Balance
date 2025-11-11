//
//  LLMService.swift
//  BalanceApp
//
//  Created by j.zembower on 11/8/25.
//

import Foundation
import Combine

class LLMService: ObservableObject {
    static let shared = LLMService()
    
    private let apiKey = Config.llmAPIKey
    private let apiURL = Config.llmAPIURL
    private let model = Config.llmModel
    
    private init() {}
    
    /// Main analysis function with user context
    func analyzeFocusCues(
        user: User?,
        healthData: HealthData,
        userInput: UserInput,
        completion: @escaping (Result<FocusAnalysis, Error>) -> Void
    ) {
        // Validate user context
        guard let user = user else {
            completion(.failure(LLMError.noUserContext))
            return
        }
        
        // Validate API key
        guard !apiKey.isEmpty else {
            completion(.failure(LLMError.missingAPIKey))
            return
        }
        
        // Validate data first
        let healthValidation = healthData.validate()
        let inputValidation = userInput.validate()
        
        if !healthValidation.isValid {
            let errorMessage = healthValidation.errors.joined(separator: ", ")
            completion(.failure(LLMError.validationFailed(errorMessage)))
            return
        }
        
        if !inputValidation.isValid {
            let errorMessage = inputValidation.errors.joined(separator: ", ")
            completion(.failure(LLMError.validationFailed(errorMessage)))
            return
        }
        
        // Create prompt for LLM
        let prompt = createPrompt(user: user, healthData: healthData, userInput: userInput)
        
        // Make API call
        guard let url = URL(string: apiURL) else {
            completion(.failure(LLMError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // OpenRouter specific headers
        if Config.apiProvider == .openrouter {
            request.setValue("BalanceApp", forHTTPHeaderField: "HTTP-Referer")
            request.setValue("BalanceApp/1.0", forHTTPHeaderField: "X-Title")
        }
        
        request.timeoutInterval = 30
        
        let body: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "system",
                    "content": """
                    You are a health and focus analysis assistant. Analyze health data and provide insights about focus patterns, stress indicators, and recommendations.
                    
                    Always provide:
                    1. A focus score from 0-100
                    2. Clear analysis of patterns
                    3. 3-5 specific, actionable recommendations
                    4. Any concerning patterns
                    
                    Format your response with clear sections.
                    """
                ],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 1000
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(LLMError.invalidResponse))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                var errorMessage = "API returned status code \(httpResponse.statusCode)"
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = json["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    errorMessage = message
                }
                completion(.failure(LLMError.apiError(httpResponse.statusCode, errorMessage)))
                return
            }
            
            guard let data = data else {
                completion(.failure(LLMError.noData))
                return
            }
            
            // Parse response
            do {
                let result = try JSONDecoder().decode(LLMResponse.self, from: data)
                let analysis = self.parseAnalysis(from: result, userID: user.id)
                completion(.success(analysis))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    /// Create detailed prompt for LLM
    private func createPrompt(user: User, healthData: HealthData, userInput: UserInput) -> String {
        let avgHeartRate = healthData.averageHeartRate
        
        return """
        Analyze the following data to identify focus cues and patterns for \(user.name):
        
        **Health Data:**
        - Average Heart Rate: \(String(format: "%.0f", avgHeartRate)) bpm
        - Recent Heart Rates: \(healthData.heartRate.prefix(5).map { String(format: "%.0f", $0) }.joined(separator: ", ")) bpm
        - Average Sleep: \(String(format: "%.1f", healthData.sleepHours)) hours/night (past 7 days)
        - Today's Steps: \(Int(healthData.stepCount))
        - Active Minutes: \(Int(healthData.activeMinutes))
        
        **User Input:**
        - Activity: \(userInput.activity)
        - Duration: \(String(format: "%.1f", userInput.duration)) hours
        - Self-Reported Stress Level: \(userInput.stressLevel)/10
        - Self-Reported Focus Level: \(userInput.focusLevel)/10
        
        **Please provide:**
        1. **Focus Score** (0-100) based on all factors
        2. **Analysis** of focus patterns based on vital signs and activity
        3. **Stress Indicators** from the data
        4. **3-5 Specific Recommendations** for optimal focus
        5. **Concerning Patterns** or anomalies that need attention
        
        Be specific and actionable in your recommendations.
        """
    }
    
    /// Parse LLM response into FocusAnalysis
    private func parseAnalysis(from response: LLMResponse, userID: String) -> FocusAnalysis {
        let content = response.choices.first?.message.content ?? "No analysis available"
        
        let focusScore = extractFocusScore(from: content)
        let recommendations = extractRecommendations(from: content)
        
        return FocusAnalysis(
            id: UUID().uuidString,
            summary: content,
            focusScore: focusScore,
            recommendations: recommendations,
            timestamp: Date(),
            userID: userID
        )
    }
    
    /// Extract focus score from LLM response
    private func extractFocusScore(from text: String) -> Double {
        let patterns = [
            #"[Ff]ocus [Ss]core:?\s*(\d+)"#,
            #"[Ss]core:?\s*(\d+)"#,
            #"(\d+)\s*/\s*100"#,
            #"(\d+)%"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text),
               let score = Double(text[range]) {
                return min(max(score, 0), 100)
            }
        }
        
        // Default to 50 if no score found
        return 50
    }
    
    /// Extract recommendations from LLM response
    private func extractRecommendations(from text: String) -> [String] {
        var recommendations: [String] = []
        
        let lines = text.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            // Match numbered lists, bullets, or dashes
            if trimmed.range(of: #"^[\d]+\.|^[•\-\*]"#, options: .regularExpression) != nil {
                let cleaned = trimmed.replacingOccurrences(
                    of: #"^[\d]+\.|^[•\-\*]\s*"#,
                    with: "",
                    options: .regularExpression
                )
                if !cleaned.isEmpty && cleaned.count > 10 {
                    recommendations.append(cleaned)
                }
            }
        }
        
        // Fallback recommendations if none found
        if recommendations.isEmpty {
            recommendations = [
                "Continue monitoring your health metrics regularly",
                "Maintain a consistent sleep schedule of 7-9 hours",
                "Take regular breaks during focused work sessions",
                "Stay hydrated and maintain regular meal times"
            ]
        }
        
        return Array(recommendations.prefix(5))
    }
}

// MARK: - Response Models

struct LLMResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
    }
    
    struct Message: Codable {
        let content: String
    }
}


// MARK: - Error Types

enum LLMError: LocalizedError {
    case noUserContext
    case missingAPIKey
    case validationFailed(String)
    case invalidURL
    case invalidResponse
    case apiError(Int, String)
    case noData
    
    var errorDescription: String? {
        switch self {
        case .noUserContext:
            return "User not found. Please restart the app."
        case .missingAPIKey:
            return "API key not configured. Please add your API key to Secrets.plist"
        case .validationFailed(let message):
            return "Validation failed: \(message)"
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let code, let message):
            return "API Error (\(code)): \(message)"
        case .noData:
            return "No data received from server"
        }
    }
}
