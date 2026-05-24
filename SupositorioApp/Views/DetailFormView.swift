import SwiftUI

struct DetailFormView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var session: UserSession
    
    let isNew: Bool
    let entorno: String
    let onSave: () -> Void
    
    @State private var recordID: String = ""
    @State private var nombre: String = ""
    @State private var telefono: String = ""
    @State private var consulta: String = ""
    @State private var solucion: String = ""
    @State private var jiraUrl: String = ""
    
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    var originalRecord: SupositorioRecord?
    
    init(record: SupositorioRecord?, isNew: Bool, entorno: String, onSave: @escaping () -> Void) {
        self.originalRecord = record
        self.isNew = isNew
        self.entorno = entorno
        self.onSave = onSave
        
        if let r = record {
            _recordID = State(initialValue: r.recordID)
            _nombre = State(initialValue: r.nombre)
            _telefono = State(initialValue: r.telefono)
            _consulta = State(initialValue: r.consulta)
            _solucion = State(initialValue: r.solucion)
            _jiraUrl = State(initialValue: r.jira_url)
        }
    }
    
    var body: some View {
        Form {
            Section(header: Text("Información Principal")) {
                TextField("ID (ej. NOTA-1)", text: $recordID)
                TextField("Nombre", text: $nombre)
                TextField("Teléfono", text: $telefono)
                    .keyboardType(.phonePad)
            }
            
            Section(header: Text("Detalles")) {
                VStack(alignment: .leading) {
                    Text("Consulta").font(.caption).foregroundColor(.secondary)
                    TextEditor(text: $consulta)
                        .frame(minHeight: 80)
                }
                
                VStack(alignment: .leading) {
                    Text("Solución").font(.caption).foregroundColor(.secondary)
                    TextEditor(text: $solucion)
                        .frame(minHeight: 80)
                }
            }
            
            Section(header: Text("Enlaces")) {
                TextField("URL de Jira", text: $jiraUrl)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
            }
            

            
            if let error = errorMessage {
                Section {
                    Text(error).foregroundColor(.red)
                }
            }
        }
        .navigationTitle(isNew ? "Nuevo Registro" : "Editar Registro")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: saveRecord) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Text("Guardar").fontWeight(.bold)
                    }
                }
                .disabled(isSaving || recordID.isEmpty || nombre.isEmpty)
            }
        }
    }
    
    private func saveRecord() {
        guard let token = session.authToken else { return }
        isSaving = true
        errorMessage = nil
        
        let recordToSave = SupositorioRecord(
            id_sistema: originalRecord?.id_sistema ?? 0,
            recordID: recordID,
            nombre: nombre,
            telefono: telefono,
            consulta: consulta,
            solucion: solucion,
            jira_url: jiraUrl,
            adjunto: originalRecord?.adjunto ?? "",
            fecha_registro: originalRecord?.fecha_registro ?? "",
            fecha_actualizacion: "",
            es_favorito: originalRecord?.es_favorito ?? 0,
            vista_privada: entorno == "personal" ? (session.currentUser?.usuario ?? "general") : "general"
        )
        
        Task {
            do {
                if isNew {
                    try await NetworkManager.shared.createRecord(recordToSave, token: token)
                } else {
                    try await NetworkManager.shared.updateRecord(recordToSave, token: token)
                }
                
                await MainActor.run {
                    isSaving = false
                    onSave()
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = "Error al guardar: \(error.localizedDescription)"
                }
            }
        }
    }
}
