import Foundation

enum RecordCategory: String {
    case jira = "J"
    case nota = "N"
    case spain = "ES"
    case latam = "LT"
}

struct SupositorioRecord: Codable, Identifiable {
    var id: String { String(id_sistema) }
    
    let id_sistema: Int
    var recordID: String
    var nombre: String
    var telefono: String
    var consulta: String
    var solucion: String
    var jira_url: String
    var adjunto: String
    var fecha_registro: String
    var fecha_actualizacion: String
    var es_favorito: Int
    var vista_privada: String
    
    enum CodingKeys: String, CodingKey {
        case id_sistema
        case recordID = "ID"
        case nombre
        case telefono
        case consulta
        case solucion
        case jira_url
        case adjunto
        case fecha_registro
        case fecha_actualizacion
        case es_favorito
        case vista_privada
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id_sistema = try container.decodeIfPresent(Int.self, forKey: .id_sistema) ?? 0
        recordID = try container.decodeIfPresent(String.self, forKey: .recordID) ?? ""
        nombre = try container.decodeIfPresent(String.self, forKey: .nombre) ?? ""
        telefono = try container.decodeIfPresent(String.self, forKey: .telefono) ?? ""
        consulta = try container.decodeIfPresent(String.self, forKey: .consulta) ?? ""
        solucion = try container.decodeIfPresent(String.self, forKey: .solucion) ?? ""
        jira_url = try container.decodeIfPresent(String.self, forKey: .jira_url) ?? ""
        adjunto = try container.decodeIfPresent(String.self, forKey: .adjunto) ?? ""
        fecha_registro = try container.decodeIfPresent(String.self, forKey: .fecha_registro) ?? ""
        fecha_actualizacion = try container.decodeIfPresent(String.self, forKey: .fecha_actualizacion) ?? ""
        es_favorito = try container.decodeIfPresent(Int.self, forKey: .es_favorito) ?? 0
        vista_privada = try container.decodeIfPresent(String.self, forKey: .vista_privada) ?? "general"
    }
    
    init(id_sistema: Int, recordID: String, nombre: String, telefono: String, consulta: String, solucion: String, jira_url: String, adjunto: String, fecha_registro: String, fecha_actualizacion: String, es_favorito: Int, vista_privada: String) {
        self.id_sistema = id_sistema
        self.recordID = recordID
        self.nombre = nombre
        self.telefono = telefono
        self.consulta = consulta
        self.solucion = solucion
        self.jira_url = jira_url
        self.adjunto = adjunto
        self.fecha_registro = fecha_registro
        self.fecha_actualizacion = fecha_actualizacion
        self.es_favorito = es_favorito
        self.vista_privada = vista_privada
    }
    
    var isFavorite: Bool {
        return es_favorito == 1
    }
    
    var category: RecordCategory {
        if !jira_url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .jira
        }
        
        let upperID = recordID.uppercased()
        let upperPhone = telefono.uppercased()
        if upperID.hasPrefix("NOTA") || upperPhone.hasPrefix("NOTA") {
            return .nota
        }
        
        let phoneStr = telefono.trimmingCharacters(in: .whitespacesAndNewlines)
        if phoneStr.hasPrefix("6") || phoneStr.hasPrefix("7") || phoneStr.hasPrefix("9") || phoneStr.hasPrefix("+34") || phoneStr.hasPrefix("0034") {
            return .spain
        }
        
        return .latam
    }
}

struct RecordsResponse: Codable {
    let success: Bool
    let data: [SupositorioRecord]?
    let message: String?
}

struct BasicResponse: Codable {
    let success: Bool
    let message: String?
    let id_sistema: Int?
}

