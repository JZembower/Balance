//
//  FocusAnalysis.swift
//  BalanceApp
//
//  Created by j.zembower on 11/10/25.
//


//
//  FocusAnalysis.swift
//  BalanceApp
//
//  Created by j.zembower on 11/10/25.
//

import Foundation

/// Model representing a focus analysis result
struct FocusAnalysis: Codable, Identifiable {
    let id: String
    let summary: String
    let focusScore: Double
    let recommendations: [String]
    let timestamp: Date
    let userID: String?
    
    /// Initialize with all parameters
    init(
        id: String = UUID().uuidString,
        summary: String,
        focusScore: Double,
        recommendations: [String],
        timestamp: Date = Date(),
        userID: String? = nil
    ) {
        self.id = id
        self.summary = summary
        self.focusScore = focusScore
        self.recommendations = recommendations
        self.timestamp = timestamp
        self.userID = userID
    }
}