import SwiftUI

struct LoginView: View {
    @EnvironmentObject var session: UserSession
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isRegisterMode = false
    @State private var showSuccessScreen = false
    @State private var registeredUsername = ""
    
    private var isPasswordValid: Bool {
        password.count >= 6
    }
    
    private var passwordsMatch: Bool {
        password == confirmPassword
    }
    
    private var isFormValid: Bool {
        if isRegisterMode {
            return !username.isEmpty && isPasswordValid && passwordsMatch
        } else {
            return !username.isEmpty && !password.isEmpty
        }
    }
    
    var body: some View {
        Group {
            if showSuccessScreen {
                successView
            } else {
                loginFormView
            }
        }
        .animation(.easeInOut(duration: 0.4), value: showSuccessScreen)
    }
    
    var successView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 90, height: 90)
                .foregroundColor(.green)
            Text("¡Cuenta creada!")
                .font(.system(size: 28, weight: .bold, design: .rounded))
            Text("El usuario **\(registeredUsername)** se ha registrado correctamente.\nAhora puedes iniciar sesión.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .background(Color(.systemBackground).edgesIgnoringSafeArea(.all))
    }
    
    var loginFormView: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 30) {
                    Spacer(minLength: 0)
                    
                    VStack(spacing: 15) {
                        Text("💊")
                            .font(.system(size: 80))
                            .rotationEffect(.degrees(15))
                            .shadow(color: .indigo.opacity(0.3), radius: 15, x: 0, y: 8)
                        
                        Text("Supositorio")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                    }
                    
                    VStack(spacing: 16) {
                        TextField("Usuario", text: $username)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        SecureField("Contraseña", text: $password)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        
                        if isRegisterMode {
                            SecureField("Confirmar contraseña", text: $confirmPassword)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        if isRegisterMode {
                            HStack(spacing: 6) {
                                Image(systemName: isPasswordValid ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(isPasswordValid ? .green : .gray)
                                Text("Mínimo 6 caracteres").font(.caption).foregroundColor(isPasswordValid ? .green : .gray)
                            }
                            HStack(spacing: 6) {
                                Image(systemName: passwordsMatch && !confirmPassword.isEmpty ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(passwordsMatch && !confirmPassword.isEmpty ? .green : .gray)
                                Text("Las contraseñas coinciden").font(.caption).foregroundColor(passwordsMatch && !confirmPassword.isEmpty ? .green : .gray)
                            }
                        }
                        
                        if let error = errorMessage {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red)
                                Text(error).font(.footnote).foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.horizontal, 34)
                    
                    Button(action: isRegisterMode ? performRegister : performLogin) {
                        HStack {
                            if isLoading {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text(isRegisterMode ? "Crear Cuenta" : "Iniciar Sesión").fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isFormValid ? Color.indigo : Color.indigo.opacity(0.4))
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .shadow(color: isFormValid ? .indigo.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                    }
                    .disabled(!isFormValid || isLoading)
                    .padding(.horizontal, 30)
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isRegisterMode.toggle()
                            errorMessage = nil
                            password = ""
                            confirmPassword = ""
                        }
                    }) {
                        Text(isRegisterMode ? "¿Ya tienes cuenta? Inicia sesión" : "¿No tienes cuenta? Regístrate")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.indigo)
                    }
                    
                    Spacer(minLength: 0)
                }
                .frame(minHeight: geometry.size.height)
            }
        }
        .background(Color(.systemBackground).edgesIgnoringSafeArea(.all))
    }
    
    private func performLogin() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let response = try await NetworkManager.shared.login(usuario: username, pass: password)
                await MainActor.run {
                    isLoading = false
                    if response.success, let token = response.token, let user = response.user {
                        session.login(token: token, user: user)
                    } else {
                        errorMessage = response.message ?? "Credenciales inválidas"
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Error de conexión: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func performRegister() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let response = try await NetworkManager.shared.register(usuario: username, pass: password)
                await MainActor.run {
                    isLoading = false
                    if response.success {
                        registeredUsername = username
                        withAnimation {
                            showSuccessScreen = true
                            username = ""; password = ""; confirmPassword = ""
                            isRegisterMode = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            withAnimation { showSuccessScreen = false }
                        }
                    } else {
                        errorMessage = response.message ?? "Error al registrar usuario"
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Error de conexión: \(error.localizedDescription)"
                }
            }
        }
    }
}
