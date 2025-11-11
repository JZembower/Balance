//
//  UserInput.swift
//  BalanceApp
//
//  Created by j.zembower on 11/8/25.
//

import Foundation

struct UserInput: Codable {
    var activity: String
    var duration: Double
    var stressLevel: Int
    var focusLevel: Int
    var timestamp: Date
    
    /// Enhanced validation with specific error messages
    func validate() -> ValidationResult {
        var errors: [String] = []
        
        // Activity validation
        if activity.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append("Activity type cannot be empty")
        }
        
        // Duration validation with realistic bounds
        if duration > 16 {
            errors.append("⚠️ Activity duration exceeds 16 hours - this is unusually long")
        } else if duration > 12 {
            errors.append("⚠️ Activity duration over 12 hours - consider taking breaks")
        }
        
        if duration <= 0 {
            errors.append("Duration must be greater than 0")
        }
        
        if duration > 24 {
            errors.append("❌ Activity duration cannot exceed 24 hours")
        }
        
        // Stress level validation
        if stressLevel < 1 || stressLevel > 10 {
            errors.append("Stress level must be between 1-10")
        }
        
        // Focus level validation
        if focusLevel < 1 || focusLevel > 10 {
            errors.append("Focus level must be between 1-10")
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
}

struct ValidationResult {
    let isValid: Bool
    let errors: [String]
}
