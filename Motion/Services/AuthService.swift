//
//  AuthService.swift
//  Motion
//
//  MOCK authentication. Accounts live in UserDefaults with a salted SHA-256
//  hash. Replace with a real backend + Keychain before shipping.
//

import Foundation
import CryptoKit

struct UserProfile: Codable, Equatable {
    var name: String
    var email: String
    var joinedAt: Date

    var firstName: String {
        name.split(separator: " ").first.map(String.init) ?? name
    }

    var initials: String {
        let parts = name.split(separator: " ").prefix(2)
        let letters = parts.compactMap { $0.first }.map { String($0) }.joined()
        return letters.isEmpty ? "M" : letters.uppercased()
    }
}

final class AuthService: ObservableObject {
    enum AuthError: LocalizedError {
        case emptyName, invalidEmail, weakPassword, emailTaken, invalidCredentials

        var errorDescription: String? {
            switch self {
            case .emptyName: return "Please enter your name."
            case .invalidEmail: return "Please enter a valid email address."
            case .weakPassword: return "Password must be at least 6 characters."
            case .emailTaken: return "An account with this email already exists."
            case .invalidCredentials: return "Incorrect email or password."
            }
        }
    }

    private struct Account: Codable {
        var profile: UserProfile
        var passwordHash: String
    }

    @Published private(set) var currentUser: UserProfile?

    var isAuthenticated: Bool { currentUser != nil }

    private let defaults: UserDefaults
    private let sessionKey = "motion.session.email"
    private let accountsKey = "motion.accounts"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let email = defaults.string(forKey: sessionKey),
           let account = loadAccounts()[email] {
            currentUser = account.profile
        }
    }

    // MARK: Public API

    func signUp(name: String, email: String, password: String) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = normalized(email)
        guard !trimmedName.isEmpty else { throw AuthError.emptyName }
        guard isValidEmail(key) else { throw AuthError.invalidEmail }
        guard password.count >= 6 else { throw AuthError.weakPassword }
        var accounts = loadAccounts()
        guard accounts[key] == nil else { throw AuthError.emailTaken }

        let profile = UserProfile(name: trimmedName, email: key, joinedAt: Date())
        accounts[key] = Account(profile: profile, passwordHash: hash(password, salt: key))
        saveAccounts(accounts)
        startSession(for: profile)
    }

    func logIn(email: String, password: String) throws {
        let key = normalized(email)
        guard isValidEmail(key) else { throw AuthError.invalidEmail }
        guard let account = loadAccounts()[key],
              account.passwordHash == hash(password, salt: key) else {
            throw AuthError.invalidCredentials
        }
        startSession(for: account.profile)
    }

    /// One-tap demo account for testing.
    func continueAsDemo() {
        let key = "demo@motion.app"
        var accounts = loadAccounts()
        if let existing = accounts[key] {
            startSession(for: existing.profile)
            return
        }
        let profile = UserProfile(name: "Alex Runner", email: key, joinedAt: Date())
        accounts[key] = Account(profile: profile, passwordHash: hash("demo123", salt: key))
        saveAccounts(accounts)
        startSession(for: profile)
    }

    func signOut() {
        defaults.removeObject(forKey: sessionKey)
        currentUser = nil
    }

    // MARK: Private

    private func startSession(for profile: UserProfile) {
        defaults.set(profile.email, forKey: sessionKey)
        currentUser = profile
    }

    private func normalized(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: email)
    }

    private func hash(_ password: String, salt: String) -> String {
        let digest = SHA256.hash(data: Data((salt + ":" + password).utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func loadAccounts() -> [String: Account] {
        guard let data = defaults.data(forKey: accountsKey),
              let accounts = try? JSONDecoder().decode([String: Account].self, from: data) else { return [:] }
        return accounts
    }

    private func saveAccounts(_ accounts: [String: Account]) {
        if let data = try? JSONEncoder().encode(accounts) {
            defaults.set(data, forKey: accountsKey)
        }
    }
}
