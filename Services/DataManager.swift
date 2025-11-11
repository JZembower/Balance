//
//  DataManager.swift
//  BalanceApp
//
//  Created by j.zembower on 11/8/25.
//

import Foundation
import Combine

class DataManager: ObservableObject {
    static let shared = DataManager()
    
    private let userDefaults = UserDefaults.standard
    private let analysisKey = "savedAnalyses"
    private let maxStoredAnalyses = 50
    
    @Published var recentAnalyses: [FocusAnalysis] = []
    
    private init() {
        loadRecentAnalyses()
    }
    
    /// Save analysis with automatic cleanup
    func saveAnalysis(_ analysis: FocusAnalysis) {
        var analyses = loadAnalysesRaw()
        
        let dict: [String: Any] = [
            "id": analysis.id,
            "summary": analysis.summary,
            "focusScore": analysis.focusScore,
            "recommendations": analysis.recommendations,
            "timestamp": analysis.timestamp.timeIntervalSince1970,
            "userID": analysis.userID ?? "unknown"
        ]
        
        analyses.append(dict)
        
        // Keep only last N analyses
        if analyses.count > maxStoredAnalyses {
            analyses = Array(analyses.suffix(maxStoredAnalyses))
        }
        
        userDefaults.set(analyses, forKey: analysisKey)
        loadRecentAnalyses()
    }
    
    /// Load raw analysis dictionaries
    private func loadAnalysesRaw() -> [[String: Any]] {
        return userDefaults.array(forKey: analysisKey) as? [[String: Any]] ?? []
    }
    
    /// Load recent analyses into published property
    private func loadRecentAnalyses() {
        recentAnalyses = getAnalysisHistory()
    }
    
    /// Get full analysis history
    func getAnalysisHistory() -> [FocusAnalysis] {
        let analyses = loadAnalysesRaw()
        
        return analyses.compactMap { dict in
            guard let id = dict["id"] as? String,
                  let summary = dict["summary"] as? String,
                  let focusScore = dict["focusScore"] as? Double,
                  let recommendations = dict["recommendations"] as? [String],
                  let timestamp = dict["timestamp"] as? TimeInterval else {
                return nil
            }
            
            let userID = dict["userID"] as? String
            
            return FocusAnalysis(
                id: id,
                summary: summary,
                focusScore: focusScore,
                recommendations: recommendations,
                timestamp: Date(timeIntervalSince1970: timestamp),
                userID: userID
            )
        }.sorted { $0.timestamp > $1.timestamp } // Most recent first
    }
    
    /// Get analyses for specific user
    func getAnalysisHistory(forUserID userID: String) -> [FocusAnalysis] {
        return getAnalysisHistory().filter { $0.userID == userID }
    }
    
    /// Clear all history
    func clearHistory() {
        userDefaults.removeObject(forKey: analysisKey)
        loadRecentAnalyses()
    }
    
    /// Delete specific analysis
    func deleteAnalysis(withID id: String) {
        var analyses = loadAnalysesRaw()
        analyses.removeAll { dict in
            (dict["id"] as? String) == id
        }
        userDefaults.set(analyses, forKey: analysisKey)
        loadRecentAnalyses()
    }
}
