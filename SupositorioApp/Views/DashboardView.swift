import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var session: UserSession
    @State private var records: [SupositorioRecord] = []
    @State private var searchText = ""
    @State private var selectedEntorno = "general"
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedFilter: String = "todos"
    @State private var selectedMonth: String? = nil
    
    @AppStorage("appTheme") private var appTheme: Int = 0
    
    var allMonths: [(id: String, name: String)] {
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMMM"
        displayFormatter.locale = Locale(identifier: "es_ES")
        let currentYear = Calendar.current.component(.year, from: Date())
        return (1...12).map { month in
            let id = String(format: "%02d-%d", month, currentYear)
            var components = DateComponents()
            components.month = month
            let date = Calendar.current.date(from: components)!
            return (id: id, name: displayFormatter.string(from: date).capitalized)
        }
    }
    
    let filters = [
        ("todos", "Todos", "square.grid.2x2"),
        ("jira", "Jira", "link"),
        ("nota", "Notas", "note.text"),
        ("spain", "España", "flag"),
        ("latam", "Latam", "globe"),
        ("favoritos", "Favoritos", "star.fill")
    ]
    
    var filteredRecords: [SupositorioRecord] {
        var result = records
        if selectedFilter == "favoritos" {
            result = result.filter { $0.es_favorito == 1 }
        } else if selectedFilter != "todos" {
            result = result.filter { record in
                switch selectedFilter {
                case "jira": return record.category == .jira
                case "nota": return record.category == .nota
                case "spain": return record.category == .spain
                case "latam": return record.category == .latam
                default: return true
                }
            }
        }
        
        if let monthId = selectedMonth {
            let idFormatter = DateFormatter(); idFormatter.dateFormat = "MM-yyyy"
            let inputFormatter = DateFormatter(); inputFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            result = result.filter { record in
                if let date = inputFormatter.date(from: record.fecha_registro) {
                    return idFormatter.string(from: date) == monthId
                }
                return false
            }
        }
        
        let sorted = result.sorted { $0.fecha_registro > $1.fecha_registro }
        if searchText.isEmpty { return sorted }
        return sorted.filter { $0.nombre.localizedCaseInsensitiveContains(searchText) || $0.telefono.localizedCaseInsensitiveContains(searchText) || $0.recordID.localizedCaseInsensitiveContains(searchText) || $0.consulta.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all)
                VStack(spacing: 0) {
                    Picker("Entorno", selection: $selectedEntorno) {
                        Text("General").tag("general")
                        Text("Personal").tag("personal")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .onChange(of: selectedEntorno) { _ in Task { await fetchRecords() } }
                    
                    HStack(spacing: 4) {
                        ForEach(filters, id: \.0) { filter in
                            Button(action: { 
                                selectedFilter = filter.0
                                if filter.0 == "todos" { selectedMonth = nil }
                            }) {
                                Text(filter.1)
                                    .font(.system(size: 11, weight: .medium))
                                    .padding(.horizontal, 8).padding(.vertical, 6)
                                    .frame(maxWidth: .infinity)
                                    .background(selectedFilter == filter.0 ? Color.indigo : Color(.secondarySystemGroupedBackground))
                                    .foregroundColor(selectedFilter == filter.0 ? .white : .primary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal, 10).padding(.top, 4).padding(.bottom, 8)
                    
                    if isLoading && records.isEmpty {
                        Spacer(); ProgressView("Cargando..."); Spacer()
                    } else if let error = errorMessage {
                        Spacer(); Text(error).foregroundColor(.red).padding()
                        Button("Reintentar") { Task { await fetchRecords() } }; Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 14) {
                                ForEach(filteredRecords) { record in
                                    ZStack {
                                        RecordCardView(record: record, toggleFavoriteAction: {
                                            Task { await toggleFavorito(for: record) }
                                        })
                                        NavigationLink(destination: RecordDetailView(record: record, entorno: selectedEntorno, onSave: { Task { await fetchRecords() } })) {
                                            Color.clear
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                        .refreshable { await fetchRecords() }
                    }
                }
            }
            .navigationTitle("Supositorio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 15) {
                        Menu {
                            Button("Todos los meses") { selectedMonth = nil }
                            Divider()
                            ForEach(allMonths, id: \.id) { month in
                                Button(month.name) { selectedMonth = month.id }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                if let month = selectedMonth {
                                    Text(allMonths.first(where: { $0.id == month })?.name.prefix(3).capitalized ?? "").font(.caption2).fontWeight(.bold)
                                }
                            }
                            .foregroundColor(selectedMonth != nil ? .orange : .indigo)
                        }
                        NavigationLink(destination: DetailFormView(record: nil, isNew: true, entorno: selectedEntorno, onSave: { Task { await fetchRecords() } })) {
                            Image(systemName: "plus.circle.fill").font(.title2).foregroundColor(.indigo)
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Text("Sesión: \(session.currentUser?.usuario ?? "-")")
                        Divider()
                        Button { appTheme = (appTheme == 2) ? 1 : 2 } label: {
                            Label(appTheme == 2 ? "Modo Claro" : "Modo Oscuro", systemImage: appTheme == 2 ? "sun.max" : "moon.fill")
                        }
                        Divider()
                        Button(role: .destructive) { session.logout() } label: {
                            Label("Cerrar sesión", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "person.circle.fill").foregroundColor(.secondary)
                            Text(session.currentUser?.usuario ?? "").font(.subheadline).foregroundColor(.secondary)
                            Image(systemName: "chevron.down").font(.caption2).foregroundColor(.secondary)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Buscar...")
        }
        .preferredColorScheme(appTheme == 0 ? nil : (appTheme == 1 ? .light : .dark))
        .onAppear { Task { await fetchRecords() } }
    }
    
    private func toggleFavorito(for record: SupositorioRecord) async {
        guard let token = session.authToken else { return }
        let newStatus = record.es_favorito == 0
        if let index = records.firstIndex(where: { $0.id_sistema == record.id_sistema }) {
            records[index].es_favorito = newStatus ? 1 : 0
        }
        do {
            try await NetworkManager.shared.toggleFavorito(id: record.id_sistema, isFavorite: newStatus, token: token)
        } catch {
            if let index = records.firstIndex(where: { $0.id_sistema == record.id_sistema }) {
                records[index].es_favorito = record.es_favorito
            }
        }
    }
    
    private func fetchRecords() async {
        guard let token = session.authToken else { return }
        await MainActor.run { isLoading = true; errorMessage = nil }
        do {
            let fetched = try await NetworkManager.shared.fetchRecords(entorno: selectedEntorno, token: token)
            await MainActor.run { records = fetched; isLoading = false }
        } catch {
            await MainActor.run { errorMessage = "Error: \(error.localizedDescription)"; isLoading = false }
        }
    }
}
