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
    
    /// Computed property for average heart rate
    var averageHeartRate: Double {
        guard !heartRate.isEmpty else { return 0 }
        return heartRate.reduce(0, +) / Double(heartRate.count)
    }
    
    /// Enhanced validation with realistic health bounds
    func validate() -> ValidationResult {
        var errors: [String] = []
        var warnings: [String] = []
        
        // Heart rate validation
        if !heartRate.isEmpty {
            let avgHR = averageHeartRate
            
            if avgHR > 200 {
                errors.append("❌ Heart rate (\(Int(avgHR)) bpm) is dangerously high")
            } else if avgHR > 120 {
                warnings.append("⚠️ Heart rate (\(Int(avgHR)) bpm) is elevated")
            } else if avgHR < 30 {
                errors.append("❌ Heart rate (\(Int(avgHR)) bpm) is dangerously low")
            } else if avgHR < 40 {
                warnings.append("⚠️ Heart rate (\(Int(avgHR)) bpm) is unusually low")
            }
        }
        
        // Sleep validation
        if sleepHours > 24 {
            errors.append("❌ Sleep duration cannot exceed 24 hours")
        } else if sleepHours > 12 {
            warnings.append("⚠️ Sleep duration (\(String(format: "%.1f", sleepHours))h) is unusually high")
        } else if sleepHours < 0 {
            errors.append("❌ Sleep duration must be positive")
        } else if sleepHours < 4 {
            warnings.append("⚠️ Sleep duration (\(String(format: "%.1f", sleepHours))h) is very low")
        }
        
        // Activity validation
        if activeMinutes > 1440 { // 24 hours in minutes
            errors.append("❌ Active time cannot exceed 24 hours")
        } else if activeMinutes > 720 { // 12 hours
            warnings.append("⚠️ Active time (\(Int(activeMinutes)) min) is very high")
        }
        
        if stepCount < 0 {
            errors.append("❌ Step count must be positive")
        } else if stepCount > 100000 {
            warnings.append("⚠️ Step count (\(Int(stepCount))) is unusually high")
        }
        
        // Combine errors and warnings
        let allMessages = errors + warnings
        
        return ValidationResult(
            isValid: errors.isEmpty,
            errors: allMessages
        )
    }
}
