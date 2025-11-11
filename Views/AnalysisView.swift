//
//  AnalysisView.swift
//  BalanceApp
//
//  Created by j.zembower on 11/8/25.
//

import SwiftUI

struct AnalysisView: View {
    let analysis: FocusAnalysis
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Focus Score Card
                VStack {
                    Text("Focus Score")
                        .font(.headline)
                    
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 20)
                            .frame(width: 150, height: 150)
                        
                        Circle()
                            .trim(from: 0, to: analysis.focusScore / 100)
                            .stroke(focusScoreColor, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                            .frame(width: 150, height: 150)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut, value: analysis.focusScore)
                        
                        VStack {
                            Text("\(Int(analysis.focusScore))")
                                .font(.system(size: 40, weight: .bold))
                            Text("/ 100")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(15)
                .shadow(radius: 5)
                
                // Summary Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Analysis Summary")
                        .font(.headline)
                    
                    Text(analysis.summary)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(15)
                .shadow(radius: 5)
                
                // Recommendations Section
                if !analysis.recommendations.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Recommendations")
                            .font(.headline)
                        
                        ForEach(Array(analysis.recommendations.enumerated()), id: \.offset) { index, recommendation in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "\(index + 1).circle.fill")
                                    .foregroundColor(.blue)
                                Text(recommendation)
                                    .font(.body)
                            }
                            .padding(.vertical, 5)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(15)
                    .shadow(radius: 5)
                }
                
                // Timestamp
                Text("Analyzed: \(formattedDate)")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private var focusScoreColor: Color {
        switch analysis.focusScore {
        case 0..<40:
            return .red
        case 40..<70:
            return .orange
        default:
            return .green
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: analysis.timestamp)
    }
}

// MARK: - Preview

struct AnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        AnalysisView(analysis: FocusAnalysis(
            id: UUID().uuidString,
            summary: "Your focus levels are optimal during morning hours when your heart rate is steady and you've had adequate sleep. Current stress indicators suggest taking short breaks every 45 minutes.",
            focusScore: 78,
            recommendations: [
                "Take a 5-minute break every 45 minutes",
                "Your heart rate variability suggests good stress management",
                "Maintain current sleep schedule (7.5 hours average)"
            ],
            timestamp: Date(),
            userID: "test-user"
        ))
    }
}
