//
//  MockHealthKitManager.swift
//  BalanceApp
//
//  Created by j.zembower on 11/8/25.
//


import Foundation
import Combine

class MockHealthKitManager: ObservableObject {
    @Published var isAuthorized = false
    
    // Simulate authorization
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isAuthorized = true
            completion(true, nil)
        }
    }
    
    // Generate realistic mock heart rate data
    func fetchHeartRate(completion: @escaping ([Double]) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Simulate realistic heart rate variations (60-100 bpm)
            let baseRate = Double.random(in: 65...75)
            let heartRates = (0..<10).map { _ in
                baseRate + Double.random(in: -5...10)
            }
            completion(heartRates)
        }
    }
    
    // Generate mock sleep data
    func fetchSleepData(days: Int, completion: @escaping (Double) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Simulate 6-9 hours of sleep per night
            let avgSleep = Double.random(in: 6.0...9.0)
            completion(avgSleep)
        }
    }
    
    // Generate mock step count
    func fetchStepCount(days: Int, completion: @escaping (Double) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Simulate 3000-12000 steps per day
            let steps = Double.random(in: 3000...12000)
            completion(steps)
        }
    }
    
    // Generate mock active minutes
    func fetchActiveMinutes(completion: @escaping (Double) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Simulate 20-120 active minutes
            let minutes = Double.random(in: 20...120)
            completion(minutes)
        }
    }
    
    // Preset scenarios for testing
    enum MockScenario {
        case wellRested      // Good sleep, moderate activity
        case stressed        // High heart rate, low sleep
        case veryActive      // High steps, high active minutes
        case sedentary       // Low steps, low activity
        case optimal         // Perfect balance
    }
    
    func fetchHealthData(scenario: MockScenario = .wellRested, completion: @escaping (HealthData) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let healthData: HealthData
            
            switch scenario {
            case .wellRested:
                healthData = HealthData(
                    heartRate: [68, 70, 69, 71, 67, 72, 70, 68, 69, 71],
                    sleepHours: 8.2,
                    stepCount: 8500,
                    activeMinutes: 45,
                    timestamp: Date()
                )
                
            case .stressed:
                healthData = HealthData(
                    heartRate: [85, 88, 90, 87, 92, 89, 91, 88, 86, 90],
                    sleepHours: 5.2,
                    stepCount: 4200,
                    activeMinutes: 25,
                    timestamp: Date()
                )
                
            case .veryActive:
                healthData = HealthData(
                    heartRate: [75, 78, 80, 77, 82, 79, 81, 78, 76, 80],
                    sleepHours: 7.5,
                    stepCount: 15000,
                    activeMinutes: 120,
                    timestamp: Date()
                )
                
            case .sedentary:
                healthData = HealthData(
                    heartRate: [65, 66, 64, 67, 65, 66, 64, 65, 66, 67],
                    sleepHours: 7.0,
                    stepCount: 2500,
                    activeMinutes: 15,
                    timestamp: Date()
                )
                
            case .optimal:
                healthData = HealthData(
                    heartRate: [70, 72, 71, 73, 70, 72, 71, 70, 72, 71],
                    sleepHours: 8.0,
                    stepCount: 10000,
                    activeMinutes: 60,
                    timestamp: Date()
                )
            }
            
            completion(healthData)
        }
    }
}