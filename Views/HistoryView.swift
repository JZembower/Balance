//
//  HistoryView.swift
//  BalanceApp
//
//  Created by j.zembower on 11/8/25.
//


import SwiftUI

struct HistoryView: View {
    @State private var analyses: [FocusAnalysis] = []
    @State private var selectedAnalysis: FocusAnalysis?
    
    var body: some View {
        List {
            if analyses.isEmpty {
                Text("No analysis history yet")
                    .foregroundColor(.gray)
                    .italic()
            } else {
                ForEach(Array(analyses.enumerated()), id: \.offset) { index, analysis in
                    Button(action: {
                        selectedAnalysis = analysis
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(formattedDate(analysis.timestamp))
                                    .font(.headline)
                                Text("Focus Score: \(Int(analysis.focusScore))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Circle()
                                .fill(scoreColor(analysis.focusScore))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text("\(Int(analysis.focusScore))")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                )
                        }
                    }
                }
            }
        }
        .navigationTitle("History")
        .onAppear {
            analyses = DataManager.shared.getAnalysisHistory().reversed()
        }
        .sheet(item: Binding(
            get: { selectedAnalysis },
            set: { selectedAnalysis = $0 }
        )) { analysis in
            NavigationView {
                AnalysisView(analysis: analysis)
                    .navigationTitle("Past Analysis")
                    .navigationBarItems(trailing: Button("Done") {
                        selectedAnalysis = nil
                    })
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 0..<40:
            return .red
        case 40..<70:
            return .orange
        default:
            return .green
        }
    }
}

// Make FocusAnalysis Identifiable for sheet
extension FocusAnalysis: Identifiable {
    var id: String {
        "\(timestamp.timeIntervalSince1970)"
    }
}