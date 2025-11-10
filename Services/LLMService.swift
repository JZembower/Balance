//
//  LLMService.swift
//  BalanceApp
//
//  Created by j.zembower on 11/8/25.
//

import Foundation
import Combine

class LLMService: ObservableObject {
    private let apiKey = Config.llmAPIKey
    private let apiURL = Config.llmAPIURL
    private let model = Config.llmModel
    
    func analyzeFocusCues(healthData: HealthData, userInput: UserInput, completion: @escaping (Result<FocusAnalysis, Error>) -> Void) {
        
        // Validate API key
        guard !apiKey.isEmpty else {
            completion(.failure(NSError(domain: "Configuration", code: 401, userInfo: [NSLocalizedDescriptionKey: "API key not configured"])))
            return
        }
        
        // Validate data first
        let healthValidation = healthData.validate()
        let inputValidation = userInput.validate()
        
        if !healthValidation.isValid || !inputValidation.isValid {
            let allErrors = healthValidation.errors + inputValidation.errors
            completion(.failure(NSError(domain: "Validation", code: 400, userInfo: [NSLocalizedDescriptionKey: allErrors.joined(separator: ", ")])))
            return
        }
        
        // Create prompt for LLM
        let prompt = createPrompt(healthData: healthData, userInput: userInput)
        
        // Make API call
        guard let url = URL(string: apiURL) else { return }
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
                ["role": "system", "content": "You are a health and focus analysis assistant. Analyze health data and provide insights about focus patterns, stress indicators, and recommendations. Format your response with clear sections and provide a focus score from 0-100."],
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
                completion(.failure(NSError(domain: "Network", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
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
                completion(.failure(NSError(domain: "API", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "Network", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            // Parse response
            do {
                let result = try JSONDecoder().decode(LLMResponse.self, from: data)
                let analysis = self.parseAnalysis(from: result)
                completion(.success(analysis))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func createPrompt(healthData: HealthData, userInput: UserInput) -> String {
        let avgHeartRate = healthData.heartRate.isEmpty ? 0 : healthData.heartRate.reduce(0, +) / Double(healthData.heartRate.count)
        
        return """
        Analyze the following data to identify focus cues and patterns:
        
        Health Data:
        - Average Heart Rate: \(String(format: "%.0f", avgHeartRate)) bpm
        - Recent Heart Rates: \(healthData.heartRate.prefix(5).map { String(format: "%.0f", $0) }.joined(separator: ", ")) bpm
        - Average Sleep: \(String(format: "%.1f", healthData.sleepHours)) hours/night (past 7 days)
        - Today's Steps: \(Int(healthData.stepCount))
        - Active Minutes: \(Int(healthData.activeMinutes))
        
        User Input:
        - Activity: \(userInput.activity)
        - Duration: \(String(format: "%.1f", userInput.duration)) hours
        - Self-Reported Stress Level: \(userInput.stressLevel)/10
        - Self-Reported Focus Level: \(userInput.focusLevel)/10
        
        Please provide:
        1. A focus score from 0-100 based on all factors
        2. Analysis of focus patterns based on vital signs and activity
        3. Stress indicators from the data
        4. 3-5 specific, actionable recommendations for optimal focus
        5. Any concerning patterns or anomalies that need attention
        
        Format your response clearly with sections.
        """
    }
    
    private func parseAnalysis(from response: LLMResponse) -> FocusAnalysis {
        let content = response.choices.first?.message.content ?? "No analysis available"
        
        let focusScore = extractFocusScore(from: content)
        let recommendations = extractRecommendations(from: content)
        
        return FocusAnalysis(
            summary: content,
            focusScore: focusScore,
            recommendations: recommendations,
            timestamp: Date()
        )
    }
    
    private func extractFocusScore(from text: String) -> Double {
        let patterns = [
            #"[Ff]ocus [Ss]core:?\s*(\d+)"#,
            #"[Ss]core:?\s*(\d+)"#,
            #"(\d+)\s*/\s*100"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text),
               let score = Double(text[range]) {
                return min(max(score, 0), 100)
            }
        }
        
        return 50
    }
    
    private func extractRecommendations(from text: String) -> [String] {
        var recommendations: [String] = []
        
        let lines = text.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.range(of: #"^[\d]+\.|^[•\-\*]"#, options: .regularExpression) != nil {
                let cleaned = trimmed.replacingOccurrences(of: #"^[\d]+\.|^[•\-\*]\s*"#, with: "", options: .regularExpression)
                if !cleaned.isEmpty {
                    recommendations.append(cleaned)
                }
            }
        }
        
        if recommendations.isEmpty {
            recommendations = [
                "Continue monitoring your health metrics",
                "Maintain consistent sleep schedule",
                "Take regular breaks during focused work"
            ]
        }
        
        return Array(recommendations.prefix(5))
    }
}

struct LLMResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
    }
    
    struct Message: Codable {
        let content: String
    }
}

struct FocusAnalysis {
    let summary: String
    let focusScore: Double
    let recommendations: [String]
    let timestamp: Date
}
