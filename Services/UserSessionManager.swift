//
//  UserSessionManager.swift
//  BalanceApp
//
//  Created by j.zembower on 11/10/25.
//

import Foundation
import Combine

/// Centralized user session and state management
class UserSessionManager: ObservableObject {
    static let shared = UserSessionManager()
    
    @Published var currentUser: User?
    @Published var isTestMode: Bool = Config.useMockData
    @Published var sessionID: String = UUID().uuidString
    
    private init() {
        // Initialize with default user or load from storage
        loadOrCreateUser()
    }
    
    private func loadOrCreateUser() {
        // Try to load existing user from UserDefaults
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
        } else {
            // Create new user
            let newUser = User(
                id: UUID().uuidString,
                name: isTestMode ? "Test User" : "User",
                createdAt: Date(),
                isTestMode: isTestMode
            )
            self.currentUser = newUser
            saveUser(newUser)
        }
    }
    
    func saveUser(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "currentUser")
        }
        self.currentUser = user
    }
    
    func resetSession() {
        sessionID = UUID().uuidString
    }
    
    func clearUser() {
        UserDefaults.standard.removeObject(forKey: "currentUser")
        currentUser = nil
    }
}

/// User model
struct User: Codable, Identifiable {
    let id: String
    var name: String
    let createdAt: Date
    var isTestMode: Bool
    
    static var mock: User {
        User(
            id: "mock-user-\(UUID().uuidString)",
            name: "Test User",
            createdAt: Date(),
            isTestMode: true
        )
    }
}
