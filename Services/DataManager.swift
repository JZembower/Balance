//
//  DataManager.swift
//  BalanceApp
//
//  Created by j.zembower on 11/8/25.
//


import Foundation

class DataManager {
    static let shared = DataManager()
    private let userDefaults = UserDefaults.standard
    private let analysisKey = "savedAnalyses"
    
    func saveAnalysis(_ analysis: FocusAnalysis) {
        var analyses = loadAnalyses()
        
        let dict: [String: Any] = [
            "summary": analysis.summary,
            "focusScore": analysis.focusScore,
            "recommendations": analysis.recommendations,
            "timestamp": analysis.timestamp.timeIntervalSince1970
        ]
        
        analyses.append(dict)
        
        // Keep only last 30 analyses
        if analyses.count > 30 {
            analyses = Array(analyses.suffix(30))
        }
        
        userDefaults.set(analyses, forKey: analysisKey)
    }
    
    func loadAnalyses() -> [[String: Any]] {
        return userDefaults.array(forKey: analysisKey) as? [[String: Any]] ?? []
    }
    
    func getAnalysisHistory() -> [FocusAnalysis] {
        let analyses = loadAnalyses()
        
        return analyses.compactMap { dict in
            guard let summary = dict["summary"] as? String,
                  let focusScore = dict["focusScore"] as? Double,
                  let recommendations = dict["recommendations"] as? [String],
                  let timestamp = dict["timestamp"] as? TimeInterval else {
                return nil
            }
            
            return FocusAnalysis(
                summary: summary,
                focusScore: focusScore,
                recommendations: recommendations,
                timestamp: Date(timeIntervalSince1970: timestamp)
            )
        }
    }
    
    func clearHistory() {
        userDefaults.removeObject(forKey: analysisKey)
    }
}