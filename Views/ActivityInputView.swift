//
//  ActivityInputView.swift
//  BalanceApp
//
//  Created by j.zembower on 11/8/25.
//

import SwiftUI
import HealthKit

struct ActivityInputView: View {
    @StateObject private var healthManager = HealthKitManager()
    @StateObject private var userSession = UserSessionManager.shared
    @StateObject private var dataManager = DataManager.shared
    
    @State private var activity = ""
    @State private var duration = 1.0
    @State private var stressLevel = 5
    @State private var focusLevel = 5
    @State private var isAnalyzing = false
    @State private var showingAnalysis = false
    @State private var analysis: FocusAnalysis?
    @State private var errorMessage: String?
    @State private var showRetry = false
    @State private var selectedScenario: MockHealthKitManager.MockScenario = .wellRested
    
    let activities = ["Studying", "Working", "Exercising", "Relaxing", "Meeting", "Creative Work"]
    
    var body: some View {
        Form {
            // Test Mode Section
            if Config.useMockData {
                Section("Testing Scenario") {
                    Picker("Health Data Scenario", selection: $selectedScenario) {
                        Text("Well Rested").tag(MockHealthKitManager.MockScenario.wellRested)
                        Text("Stressed").tag(MockHealthKitManager.MockScenario.stressed)
                        Text("Very Active").tag(MockHealthKitManager.MockScenario.veryActive)
                        Text("Sedentary").tag(MockHealthKitManager.MockScenario.sedentary)
                        Text("Optimal").tag(MockHealthKitManager.MockScenario.optimal)
                    }
                    
                    Text(scenarioDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Activity Details Section
            Section("Activity Details") {
                Picker("Activity Type", selection: $activity) {
                    ForEach(activities, id: \.self) { activity in
                        Text(activity).tag(activity)
                    }
                }
                
                VStack(alignment: .leading) {
                    Text("Duration: \(String(format: "%.1f", duration)) hours")
                    Slider(value: $duration, in: 0.5...16, step: 0.5)
                }
                
                // Duration warnings
                if duration > 12 {
                    Label("Long duration - consider taking breaks", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                if duration > 16 {
                    Label("Duration exceeds recommended limits", systemImage: "xmark.circle")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            // Self Assessment Section
            Section("Self Assessment") {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Stress Level: \(stressLevel)/10")
                        .font(.subheadline)
                    HStack {
                        Text("Low")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: Binding(
                            get: { Double(stressLevel) },
                            set: { stressLevel = Int($0) }
                        ), in: 1...10, step: 1)
                        Text("High")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Focus Level: \(focusLevel)/10")
                        .font(.subheadline)
                    HStack {
                        Text("Low")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: Binding(
                            get: { Double(focusLevel) },
                            set: { focusLevel = Int($0) }
                        ), in: 1...10, step: 1)
                        Text("High")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Analyze Button Section
            Section {
                Button(action: analyzeData) {
                    HStack {
                        if isAnalyzing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Text("Analyzing...")
                        } else {
                            Image(systemName: "brain.head.profile")
                            Text("Analyze Focus Cues")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(isAnalyzing || activity.isEmpty)
            }
            
            // Error Display Section
            if let error = errorMessage {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Analysis Failed", systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.headline)
                        
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                        
                        if showRetry {
                            Button(action: analyzeData) {
                                Label("Retry Analysis", systemImage: "arrow.clockwise")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
            
            // User Info Section (Debug)
            if Config.useMockData {
                Section("Debug Info") {
                    if let user = userSession.currentUser {
                        Text("User: \(user.name)")
                        Text("ID: \(user.id)")
                        Text("Test Mode: \(user.isTestMode ? "Yes" : "No")")
                    } else {
                        Text("No user context")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .navigationTitle("Log Activity")
        .sheet(isPresented: $showingAnalysis) {
            if let analysis = analysis {
                NavigationView {
                    AnalysisView(analysis: analysis)
                        .navigationTitle("Analysis Results")
                        .navigationBarItems(trailing: Button("Done") {
                            showingAnalysis = false
                        })
                }
            }
        }
        .onAppear {
            activity = activities[0]
        }
    }
    
    // MARK: - Computed Properties
    
    private var scenarioDescription: String {
        switch selectedScenario {
        case .wellRested:
            return "Good sleep (8.2h), moderate activity, normal heart rate"
        case .stressed:
            return "Poor sleep (5.2h), elevated heart rate, low activity"
        case .veryActive:
            return "High activity (15k steps), elevated heart rate, good sleep"
        case .sedentary:
            return "Low activity (2.5k steps), low heart rate, normal sleep"
        case .optimal:
            return "Perfect balance - 8h sleep, 10k steps, optimal vitals"
        }
    }
    
    // MARK: - Analysis Logic
    
    private func analyzeData() {
        isAnalyzing = true
        errorMessage = nil
        showRetry = false
        
        // Ensure user context exists
        guard let user = userSession.currentUser else {
            errorMessage = "User session not found. Please restart the app."
            isAnalyzing = false
            showRetry = true
            return
        }
        
        // Create user input
        let userInput = UserInput(
            activity: activity,
            duration: duration,
            stressLevel: stressLevel,
            focusLevel: focusLevel,
            timestamp: Date()
        )
        
        // Validate user input first
        let validation = userInput.validate()
        if !validation.isValid {
            errorMessage = validation.errors.joined(separator: "\n")
            isAnalyzing = false
            showRetry = false
            return
        }
        
        // Fetch health data
        fetchHealthData { healthData in
            guard let healthData = healthData else {
                DispatchQueue.main.async {
                    errorMessage = "Failed to fetch health data"
                    isAnalyzing = false
                    showRetry = true
                }
                return
            }
            
            // Validate health data
            let healthValidation = healthData.validate()
            if !healthValidation.isValid {
                DispatchQueue.main.async {
                    errorMessage = "Health data validation failed:\n" + healthValidation.errors.joined(separator: "\n")
                    isAnalyzing = false
                    showRetry = false
                }
                return
            }
            
            // Send to LLM for analysis with user context
            LLMService.shared.analyzeFocusCues(
                user: user,
                healthData: healthData,
                userInput: userInput
            ) { result in
                DispatchQueue.main.async {
                    isAnalyzing = false
                    
                    switch result {
                    case .success(let focusAnalysis):
                        // Save to history
                        dataManager.saveAnalysis(focusAnalysis)
                        
                        analysis = focusAnalysis
                        showingAnalysis = true
                        errorMessage = nil
                        
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                        showRetry = true
                    }
                }
            }
        }
    }
    
    // MARK: - Health Data Fetching
    
    private func fetchHealthData(completion: @escaping (HealthData?) -> Void) {
        if Config.useMockData {
            // Use mock data for testing with selected scenario
            let mockManager = MockHealthKitManager()
            
            mockManager.fetchHealthData(scenario: selectedScenario) { healthData in
                DispatchQueue.main.async {
                    completion(healthData)
                }
            }
        } else {
            // Use real HealthKit data
            var heartRates: [Double] = []
            var sleepHours: Double = 0
            var steps: Double = 0
            var activeMinutes: Double = 0
            
            let group = DispatchGroup()
            
            // Fetch heart rate
            group.enter()
            healthManager.fetchHeartRate { rates in
                heartRates = rates
                group.leave()
            }
            
            // Fetch sleep data
            group.enter()
            healthManager.fetchSleepData(days: 7) { samples in
                let totalSleep = samples.reduce(0.0) { sum, sample in
                    let duration = sample.endDate.timeIntervalSince(sample.startDate)
                    return sum + (duration / 3600) // Convert to hours
                }
                sleepHours = totalSleep / 7 // Average per day
                group.leave()
            }
            
            // Fetch step count
            group.enter()
            healthManager.fetchStepCount(days: 1) { count in
                steps = count
                group.leave()
            }
            
            // Fetch active minutes
            group.enter()
            healthManager.fetchActiveMinutes { minutes in
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
}

// MARK: - Preview

struct ActivityInputView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ActivityInputView()
        }
    }
}
