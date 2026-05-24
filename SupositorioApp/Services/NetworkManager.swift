import Foundation

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    private let baseURL = "http://127.0.0.1/app/api.php"
    
    private init() {}
    
    private func createRequest(url: URL, method: String, body: Data? = nil, token: String? = nil) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body = body {
            request.httpBody = body
        }
        return request
    }
    
    func login(usuario: String, pass: String) async throws -> LoginResponse {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [URLQueryItem(name: "action", value: "login")]
        
        let body = ["usuario": usuario, "password": pass]
        let bodyData = try JSONEncoder().encode(body)
        
        let request = createRequest(url: components.url!, method: "POST", body: bodyData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, 
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(LoginResponse.self, from: data)
    }
    
    func register(usuario: String, pass: String) async throws -> LoginResponse {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [URLQueryItem(name: "action", value: "register")]
        
        let body = ["usuario": usuario, "password": pass]
        let bodyData = try JSONEncoder().encode(body)
        
        let request = createRequest(url: components.url!, method: "POST", body: bodyData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            if let errorResponse = try? JSONDecoder().decode(LoginResponse.self, from: data) {
                return errorResponse
            }
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(LoginResponse.self, from: data)
    }
    
    func fetchRecords(entorno: String, token: String) async throws -> [SupositorioRecord] {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "action", value: "records"),
            URLQueryItem(name: "entorno", value: entorno)
        ]
        
        let request = createRequest(url: components.url!, method: "GET", token: token)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let res = try JSONDecoder().decode(RecordsResponse.self, from: data)
        return res.data ?? []
    }
    
    func createRecord(_ record: SupositorioRecord, token: String) async throws {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [URLQueryItem(name: "action", value: "create")]
        
        let bodyData = try JSONEncoder().encode(record)
        let request = createRequest(url: components.url!, method: "POST", body: bodyData, token: token)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
    
    func updateRecord(_ record: SupositorioRecord, token: String) async throws {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "action", value: "update"),
            URLQueryItem(name: "id", value: String(record.id_sistema))
        ]
        
        let bodyData = try JSONEncoder().encode(record)
        let request = createRequest(url: components.url!, method: "PUT", body: bodyData, token: token)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
    
    func deleteRecord(id: Int, token: String) async throws {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "action", value: "delete"),
            URLQueryItem(name: "id", value: String(id))
        ]
        
        let request = createRequest(url: components.url!, method: "DELETE", token: token)
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
    
    func toggleFavorito(id: Int, isFavorite: Bool, token: String) async throws {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "action", value: "toggleFavorito"),
            URLQueryItem(name: "id", value: String(id))
        ]
        
        let body = ["es_favorito": isFavorite ? 1 : 0]
        let bodyData = try JSONEncoder().encode(body)
        
        let request = createRequest(url: components.url!, method: "PUT", body: bodyData, token: token)
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}
