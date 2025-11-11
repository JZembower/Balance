//
//  HealthKitManager.swift
//  BalanceApp
//
//  Created by j.zembower on 11/8/25.
//

import HealthKit
import Combine

class HealthKitManager: ObservableObject {
    let healthStore = HKHealthStore()
    
    // Define data types to read
    let typesToRead: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
        HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!,
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
        HKObjectType.workoutType()
    ]
    
    // Request authorization
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, NSError(
                domain: "HealthKit",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device"]
            ))
            return
        }
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            completion(success, error)
        }
    }
    
    // Fetch heart rate
    func fetchHeartRate(completion: @escaping ([Double]) -> Void) {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            completion([])
            return
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: heartRateType,
            predicate: nil,
            limit: 10,
            sortDescriptors: [sortDescriptor]
        ) { _, results, error in
            guard let samples = results as? [HKQuantitySample], error == nil else {
                completion([])
                return
            }
            
            let heartRates = samples.map { $0.quantity.doubleValue(for: HKUnit(from: "count/min")) }
            completion(heartRates)
        }
        
        healthStore.execute(query)
    }
    
    // Fetch sleep data - returns array of samples
    func fetchSleepData(days: Int, completion: @escaping ([HKCategorySample]) -> Void) {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            completion([])
            return
        }
        
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKSampleQuery(
            sampleType: sleepType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { _, results, error in
            guard let samples = results as? [HKCategorySample], error == nil else {
                completion([])
                return
            }
            completion(samples)
        }
        
        healthStore.execute(query)
    }
    
    // Fetch step count
    func fetchStepCount(days: Int, completion: @escaping (Double) -> Void) {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion(0)
            return
        }
        
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            guard let sum = result?.sumQuantity(), error == nil else {
                completion(0)
                return
            }
            let steps = sum.doubleValue(for: HKUnit.count())
            completion(steps)
        }
        
        healthStore.execute(query)
    }
    
    // Fetch active minutes (Apple Exercise Time)
    func fetchActiveMinutes(completion: @escaping (Double) -> Void) {
        guard let exerciseType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) else {
            completion(0)
            return
        }
        
        let endDate = Date()
        let startDate = Calendar.current.startOfDay(for: endDate)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: exerciseType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            guard let sum = result?.sumQuantity(), error == nil else {
                completion(0)
                return
            }
            let minutes = sum.doubleValue(for: HKUnit.minute())
            completion(minutes)
        }
        
        healthStore.execute(query)
    }
    
    // Fetch active energy burned (alternative measure of activity)
    func fetchActiveEnergy(days: Int, completion: @escaping (Double) -> Void) {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            completion(0)
            return
        }
        
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: energyType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            guard let sum = result?.sumQuantity(), error == nil else {
                completion(0)
                return
            }
            let calories = sum.doubleValue(for: HKUnit.kilocalorie())
            completion(calories)
        }
        
        healthStore.execute(query)
    }
    
    // Fetch all health data at once (convenience method)
    func fetchAllHealthData(completion: @escaping (HealthData?) -> Void) {
        var heartRates: [Double] = []
        var sleepHours: Double = 0
        var steps: Double = 0
        var activeMinutes: Double = 0
        
        let group = DispatchGroup()
        
        // Fetch heart rate
        group.enter()
        fetchHeartRate { rates in
            heartRates = rates
            group.leave()
        }
        
        // Fetch sleep data
        group.enter()
        fetchSleepData(days: 7) { samples in
            let totalSleep = samples.reduce(0.0) { sum, sample in
                let duration = sample.endDate.timeIntervalSince(sample.startDate)
                return sum + (duration / 3600) // Convert to hours
            }
            sleepHours = totalSleep / 7 // Average per day
            group.leave()
        }
        
        // Fetch step count
        group.enter()
        fetchStepCount(days: 1) { count in
            steps = count
            group.leave()
        }
        
        // Fetch active minutes
        group.enter()
        fetchActiveMinutes { minutes in
            activeMinutes = minutes
            group.leave()
        }
        
        group.notify(queue: .main) {
            let healthData = HealthData(
                heartRate: heartRates,
                sleepHours: sleepHours,
                stepCount: steps,
                activeMinutes: activeMinutes,
                timestamp: Date()
            )
            completion(healthData)
        }
    }
}

