//
//  AuthViewModel.swift
//  Motion
//
//  Form state for the login / sign-up screen.
//

import Foundation

final class AuthViewModel: ObservableObject {
    enum Mode: String, CaseIterable, Identifiable {
        case login = "Log In"
        case signUp = "Sign Up"
        var id: String { rawValue }
    }

    @Published var mode: Mode = .login
    @Published var name = ""
    @Published var email = ""
    @Published var password = ""
    @Published var errorMessage: String?
    @Published var isLoading = false

    func submit(using auth: AuthService) {
        errorMessage = nil
        isLoading = true
        // Small delay to simulate a network round trip.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
            guard let self = self else { return }
            do {
                switch self.mode {
                case .login:
                    try auth.logIn(email: self.email, password: self.password)
                case .signUp:
                    try auth.signUp(name: self.name, email: self.email, password: self.password)
                }
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isLoading = false
        }
    }
}
