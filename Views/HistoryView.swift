//
//  HistoryView.swift
//  BalanceApp
//
//  Created by j.zembower on 11/8/25.
//

import SwiftUI

struct HistoryView: View {
    @StateObject private var dataManager = DataManager.shared
    @State private var selectedAnalysis: FocusAnalysis?
    
    var body: some View {
        List {
            if dataManager.recentAnalyses.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("No analysis history yet")
                        .foregroundColor(.gray)
                        .italic()
                    Text("Complete your first focus analysis to see results here")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                ForEach(dataManager.recentAnalyses) { analysis in
                    Button(action: {
                        selectedAnalysis = analysis
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(formattedDate(analysis.timestamp))
                                    .font(.headline)
                                Text("Focus Score: \(Int(analysis.focusScore))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                if let userID = analysis.userID {
                                    Text("User: \(userID.prefix(8))...")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Spacer()
                            
                            ZStack {
                                Circle()
                                    .fill(scoreColor(analysis.focusScore))
                                    .frame(width: 50, height: 50)
                                
                                Text("\(Int(analysis.focusScore))")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .bold()
                            }
                        }
                        .padding(.vertical, 5)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: deleteAnalyses)
            }
        }
        .navigationTitle("History")
        .toolbar {
            if !dataManager.recentAnalyses.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(role: .destructive) {
                        clearHistory()
                    } label: {
                        Label("Clear All", systemImage: "trash")
                    }
                }
            }
        }
        .sheet(item: $selectedAnalysis) { analysis in
            NavigationView {
                AnalysisView(analysis: analysis)
                    .navigationTitle("Past Analysis")
                    .navigationBarItems(trailing: Button("Done") {
                        selectedAnalysis = nil
                    })
            }
        }
    }
    
    // MARK: - Helper Functions
    
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
    
    private func deleteAnalyses(at offsets: IndexSet) {
        for index in offsets {
            let analysis = dataManager.recentAnalyses[index]
            dataManager.deleteAnalysis(withID: analysis.id)
        }
    }
    
    private func clearHistory() {
        dataManager.clearHistory()
    }
}

// MARK: - Preview

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HistoryView()
        }
    }
}
