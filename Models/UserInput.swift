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
    
    func validate() -> ValidationResult {
        var errors: [String] = []
        
        if duration > 24 {
            errors.append("Activity duration cannot exceed 24 hours")
        }
        
        if duration < 0 {
            errors.append("Duration must be positive")
        }
        
        if stressLevel < 1 || stressLevel > 10 {
            errors.append("Stress level must be between 1-10")
        }
        
        if focusLevel < 1 || focusLevel > 10 {
            errors.append("Focus level must be between 1-10")
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
}