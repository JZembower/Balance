//
//  ContentView.swift
//  BalanceApp
//
//  Created by j.zembower on 11/8/25.
//


import SwiftUI

struct ContentView: View {
    @StateObject private var healthManager = HealthKitManager()
    @StateObject private var mockHealthManager = MockHealthKitManager()
    @State private var isAuthorized = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if Config.useMockData {
                    // Mock mode - skip authorization
                    VStack(spacing: 15) {
                        Image(systemName: "testtube.2")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Balance App")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Running in TEST MODE with simulated data")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Start Testing") {
                            mockHealthManager.requestAuthorization { success, error in
                                DispatchQueue.main.async {
                                    isAuthorized = success
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top)
                    }
                } else if !isAuthorized {
                    // Real mode - require HealthKit authorization
                    VStack(spacing: 15) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                        
                        Text("Balance App")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Analyze your focus patterns using health data")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Authorize HealthKit") {
                            healthManager.requestAuthorization { success, error in
                                DispatchQueue.main.async {
                                    isAuthorized = success
                                    if let error = error {
                                        errorMessage = error.localizedDescription
                                    }
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top)
                    }
                }
                
                if isAuthorized {
                    VStack(spacing: 15) {
                        Image(systemName: Config.useMockData ? "checkmark.circle.fill" : "heart.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                        
                        Text(Config.useMockData ? "Test Mode Active" : "HealthKit Connected")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        NavigationLink(destination: ActivityInputView()) {
                            Label("Log New Activity", systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        
                        NavigationLink(destination: HistoryView()) {
                            Label("View History", systemImage: "clock.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                }
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
            }
            .navigationTitle("Balance")
            .padding()
        }
    }
}
