import SwiftUI

struct RecordDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var session: UserSession
    
    let record: SupositorioRecord
    let entorno: String
    let onSave: () -> Void
    
    @State private var showDeleteConfirm = false
    @State private var isDeleting = false
    @State private var isFavorite: Bool = false
    @State private var errorMessage: String?
    @State private var navigateToEdit = false
    
    init(record: SupositorioRecord, entorno: String, onSave: @escaping () -> Void) {
        self.record = record
        self.entorno = entorno
        self.onSave = onSave
        _isFavorite = State(initialValue: record.es_favorito == 1)
    }
    
    var categoryColor: Color {
        switch record.category {
        case .jira: return .blue
        case .nota: return .purple
        case .spain: return Color(red: 0.95, green: 0.75, blue: 0.0)
        case .latam: return .green
        }
    }
    
    var formattedDate: String {
        let input = DateFormatter()
        input.dateFormat = "yyyy-MM-dd HH:mm:ss"
        input.locale = Locale(identifier: "es_ES")
        let output = DateFormatter()
        output.dateFormat = "d MMM yyyy · HH:mm"
        output.locale = Locale(identifier: "es_ES")
        if let date = input.date(from: record.fecha_registro) {
            return output.string(from: date)
        }
        return record.fecha_registro
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    HStack(spacing: 10) {
                        Text(record.category.rawValue)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(categoryColor)
                            .clipShape(Capsule())
                        
                        Text(record.recordID)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        if session.currentUser?.rol == "admin" && record.vista_privada != "general" {
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: "person.fill")
                                Text(record.vista_privada)
                            }
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.indigo)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.indigo.opacity(0.1))
                            .cornerRadius(6)
                        } else {
                            Spacer()
                        }
                    }
                    
                    Text(record.nombre)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Divider()
                    
                    if !record.telefono.isEmpty {
                        infoRow(icon: "phone.fill", label: "Teléfono", value: record.telefono)
                    }
                    
                    infoRow(icon: "calendar", label: "Fecha de registro", value: formattedDate)
                    
                    Divider()
                    
                    if !record.consulta.isEmpty {
                        infoBlock(label: "Consulta", content: record.consulta)
                    }
                    
                    if !record.solucion.isEmpty {
                        infoBlock(label: "Solución", content: record.solucion)
                    }
                    
                    if !record.jira_url.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Enlace Jira", systemImage: "link")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            if let url = URL(string: record.jira_url) {
                                Link(record.jira_url, destination: url)
                                    .font(.footnote)
                                    .foregroundColor(.indigo)
                                    .lineLimit(2)
                            }
                        }
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                    
                    Spacer().frame(height: 90)
                }
                .padding(20)
            }
            
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: 12) {
                    Button {
                        showDeleteConfirm = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Eliminar")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.systemGray5))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                    }
                    .disabled(isDeleting)
                    
                    NavigationLink(destination: DetailFormView(
                        record: record,
                        isNew: false,
                        entorno: entorno,
                        onSave: {
                            onSave()
                            presentationMode.wrappedValue.dismiss()
                        }
                    ), isActive: $navigateToEdit) {
                        EmptyView()
                    }
                    
                    Button {
                        navigateToEdit = true
                    } label: {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Editar")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.indigo)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
            }
        }
        .navigationTitle("Detalle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { Task { await toggleFavorito() } }) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundColor(isFavorite ? .yellow : .gray)
                }
            }
        }
        .confirmationDialog(
            "¿Eliminar este registro?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Eliminar", role: .destructive) {
                Task { await deleteRecord() }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Esta acción no se puede deshacer.")
        }
    }
    
    @ViewBuilder
    func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .imageScale(.small)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
            }
        }
    }
    
    @ViewBuilder
    func infoBlock(label: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            Text(content)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private func toggleFavorito() async {
        guard let token = session.authToken else { return }
        let newStatus = isFavorite ? 0 : 1
        do {
            try await NetworkManager.shared.toggleFavorito(id: record.id_sistema, isFavorite: newStatus == 1, token: token)
            await MainActor.run {
                self.isFavorite = (newStatus == 1)
                onSave() 
            }
        } catch {
            await MainActor.run {
                errorMessage = "Error al actualizar favorito"
            }
        }
    }
    
    private func deleteRecord() async {
        guard let token = session.authToken else { return }
        await MainActor.run { isDeleting = true }
        do {
            try await NetworkManager.shared.deleteRecord(id: record.id_sistema, token: token)
            await MainActor.run {
                isDeleting = false
                onSave()
                presentationMode.wrappedValue.dismiss()
            }
        } catch {
            await MainActor.run {
                isDeleting = false
                errorMessage = "Error al eliminar: \(error.localizedDescription)"
            }
        }
    }
}
