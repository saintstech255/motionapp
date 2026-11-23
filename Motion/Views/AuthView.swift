//
//  AuthView.swift
//  Motion
//
//  Mock login / sign-up screen.
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var auth: AuthService
    @StateObject private var vm = AuthViewModel()

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            Circle().fill(Theme.brand.opacity(0.35))
                .frame(width: 340, height: 340)
                .blur(radius: 90)
                .offset(x: 130, y: -300)
            Circle().fill(Theme.electricBlue.opacity(0.22))
                .frame(width: 320, height: 320)
                .blur(radius: 90)
                .offset(x: -140, y: 340)

            ScrollView {
                VStack(spacing: 26) {
                    header
                    Picker("Mode", selection: $vm.mode.animation(.easeInOut)) {
                        ForEach(AuthViewModel.Mode.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    VStack(spacing: 14) {
                        if vm.mode == .signUp {
                            AuthField(symbol: "person.fill", placeholder: "Full name", text: $vm.name)
                                .textContentType(.name)
                        }
                        AuthField(symbol: "envelope.fill", placeholder: "Email", text: $vm.email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        AuthField(symbol: "lock.fill", placeholder: "Password", text: $vm.password, isSecure: true)
                            .textContentType(vm.mode == .signUp ? .newPassword : .password)
                    }

                    if let error = vm.errorMessage {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(Theme.danger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        vm.submit(using: auth)
                    } label: {
                        if vm.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text(vm.mode == .login ? "Log In" : "Create Account")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(vm.isLoading)

                    Button("Continue as demo user") { auth.continueAsDemo() }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)

                    Text("A Kas-Kazini Inc. app")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary.opacity(0.7))
                        .padding(.top, 20)
                }
                .padding(24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.run")
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 84, height: 84)
                .background(Theme.brandGradient, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: Theme.brand.opacity(0.5), radius: 20, y: 8)
            Text("MOTION")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .tracking(4)
            Text("Track every move. Beat every record.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.top, 40)
    }
}

private struct AuthField: View {
    let symbol: String
    let placeholder: String
    @Binding var text: String
    var isSecure = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 20)
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .padding(16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
