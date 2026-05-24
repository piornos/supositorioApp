import SwiftUI

struct RecordCardView: View {
    @EnvironmentObject var session: UserSession
    let record: SupositorioRecord
    let toggleFavoriteAction: () -> Void
    
    var formattedDate: String {
        let input = DateFormatter()
        input.dateFormat = "yyyy-MM-dd HH:mm:ss"
        input.locale = Locale(identifier: "es_ES")
        let output = DateFormatter()
        output.dateFormat = "d MMM"
        output.locale = Locale(identifier: "es_ES")
        if let date = input.date(from: record.fecha_registro) {
            return output.string(from: date)
        }
        return record.fecha_registro
    }
    
    var categoryColor: Color {
        switch record.category {
        case .jira: return .blue
        case .nota: return .purple
        case .spain: return Color(red: 0.95, green: 0.75, blue: 0.0)
        case .latam: return .green
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Text(record.category.rawValue)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 22, height: 22)
                    .background(categoryColor)
                    .clipShape(Circle())
                
                Text(record.recordID)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                if session.currentUser?.rol == "admin" && record.vista_privada != "general" {
                    Text("👤 \(record.vista_privada)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.indigo)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.indigo.opacity(0.1))
                        .cornerRadius(4)
                }
                
                if !record.jira_url.isEmpty {
                    Image(systemName: "link")
                        .font(.system(size: 10))
                        .foregroundColor(.indigo)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    Text(formattedDate)
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))
                    
                    Button(action: toggleFavoriteAction) {
                        Image(systemName: record.es_favorito == 1 ? "star.fill" : "star")
                            .font(.system(size: 16))
                            .foregroundColor(record.es_favorito == 1 ? .yellow : .gray.opacity(0.5))
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(record.nombre)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if !record.telefono.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "phone.fill").font(.system(size: 10))
                        Text(record.telefono).font(.subheadline)
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            if !record.consulta.isEmpty {
                Text(record.consulta)
                    .font(.subheadline)
                    .foregroundColor(.primary.opacity(0.8))
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}
