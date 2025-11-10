//
//  HealthDataModel.swift
//  BalanceApp
//
//  Created by j.zembower on 11/8/25.
//

import Foundation

struct HealthData: Codable {
    var heartRate: [Double]
    var sleepHours: Double
    var stepCount: Double
    var activeMinutes: Double
    var timestamp: Date
    
    // Validation with error handling
    func validate() -> ValidationResult {
        var errors: [String] = []
        
        // Check for unrealistic heart rate
        if let avgHR = heartRate.first, avgHR > 200 || avgHR < 30 {
            errors.append("Heart rate seems unusual (\(Int(avgHR)) bpm)")
        }
        
        // Check for unrealistic sleep
        if sleepHours > 24 {
            errors.append("Sleep duration cannot exceed 24 hours")
        }
        
        if sleepHours < 0 {
            errors.append("Sleep duration must be positive")
        }
        
        // Check for unrealistic activity
        if activeMinutes > 1440 { // 24 hours in minutes
            errors.append("Active time cannot exceed 24 hours")
        }
        
        if stepCount < 0 {
            errors.append("Step count must be positive")
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
}

struct ValidationResult {
    let isValid: Bool
    let errors: [String]
}
