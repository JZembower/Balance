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
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
        HKObjectType.workoutType()
    ]
    
    // Request authorization
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, nil)
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
        let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 10, sortDescriptors: [sortDescriptor]) { _, results, error in
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
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, results, error in
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
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let sum = result?.sumQuantity(), error == nil else {
                completion(0)
                return
            }
            let steps = sum.doubleValue(for: HKUnit.count())
            completion(steps)
        }
        
        healthStore.execute(query)
    }
}
