import Foundation

struct User: Codable {
    let usuario: String
    let rol: String
    let ultimo_entorno: String
    let primer_acceso: Int?
}

struct LoginResponse: Codable {
    let success: Bool
    let token: String?
    let user: User?
    let message: String?
}

class UserSession: ObservableObject {
    @Published var currentUser: User?
    @Published var authToken: String?
    
    init() {
        if let savedToken = UserDefaults.standard.string(forKey: "authToken") {
            self.authToken = savedToken
        }
        
        if let savedUserData = UserDefaults.standard.data(forKey: "currentUser"),
           let decodedUser = try? JSONDecoder().decode(User.self, from: savedUserData) {
            self.currentUser = decodedUser
        }
    }
    
    func login(token: String, user: User) {
        self.authToken = token
        self.currentUser = user
        
        UserDefaults.standard.set(token, forKey: "authToken")
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "currentUser")
        }
    }
    
    func logout() {
        self.authToken = nil
        self.currentUser = nil
        UserDefaults.standard.removeObject(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }
    
    var isLoggedIn: Bool {
        return authToken != nil
    }
}
