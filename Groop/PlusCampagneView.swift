//
//  PlusCampagneView.swift
//  Groop
//
//  Sauvegarde, restauration et partage de campagnes.
//

import SwiftUI
import UniformTypeIdentifiers
import PhotosUI

struct PlusCampagneView: View {
    @ObservedObject var store: OrderStore
    @ObservedObject var storeManager: StoreManager

    @State private var shareItem: IdentifiableURL? = nil
    @State private var showSauvegardeNom = false
    @State private var nomSauvegarde = ""
    @State private var showChargerCampagne = false
    @State private var showSauvegardeFeedback = false
    @State private var showNouvelleCampagneRappel = false
    @State private var showNouvelleCampagneOptions = false
    @State private var showCampagneSetup = false
    @State private var campagneCSVShareItem: IdentifiableURL? = nil
    @State private var showFileImporter = false
    @State private var fileImportJSON = false
    @State private var importCommandesResult: OrderStore.ImportCommandesResult? = nil
    @State private var showImportCommandesFeedback = false
    @State private var showImportImageSource = false
    @State private var showCamera = false
    @State private var showPhotosPicker = false
    @State private var isProcessingOCR = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var capturedImage: UIImage? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                configSection
                importCampagnesSection
                nouvelleCampagneSection
                sauvegardeSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Campagne")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $campagneCSVShareItem) { item in
            ShareSheet(activityItems: [item.url])
        }
        .sheet(isPresented: $showCampagneSetup) {
            CampagneSetupView(store: store)
        }
        .sheet(item: $shareItem) { item in
            ShareSheet(activityItems: [item.url])
        }
        .sheet(isPresented: $showChargerCampagne) {
            CampagneListView(store: store)
        }
        .alert("Sauvegarder la campagne", isPresented: $showSauvegardeNom) {
            TextField("Nom de la sauvegarde", text: $nomSauvegarde)
            Button("Sauvegarder") {
                if !nomSauvegarde.trimmingCharacters(in: .whitespaces).isEmpty {
                    _ = store.sauvegarderCampagne(nom: nomSauvegarde.trimmingCharacters(in: .whitespaces))
                    showSauvegardeFeedback = true
                }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Toute la campagne sera sauvegardée : commandes, réglements, variantes et catégories.")
        }
        .alert("Sauvegarde effectuée ✓", isPresented: $showSauvegardeFeedback) {
            Button("OK") {}
        } message: {
            Text("La campagne « \(nomSauvegarde) » a été sauvegardée.")
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: fileImporterAllowedTypes) { result in
            switch result {
            case .success(let url):
                let accessing = url.startAccessingSecurityScopedResource()
                defer { if accessing { url.stopAccessingSecurityScopedResource() } }
                if fileImportJSON {
                    if store.chargerCampagne(depuis: url) {
                        showSauvegardeFeedback = true
                        nomSauvegarde = store.titreCampagne
                    }
                } else {
                    let ext = url.pathExtension.lowercased()
                    if ["csv", "txt", "tsv"].contains(ext) {
                        importCommandesResult = store.importerCommandesDepuisFichier(url: url)
                        showImportCommandesFeedback = true
                    } else {
                        isProcessingOCR = true
                        store.importerCommandesDepuisPDFOuImage(url: url) { res in
                            isProcessingOCR = false
                            importCommandesResult = res
                            showImportCommandesFeedback = true
                        }
                    }
                }
            case .failure:
                break
            }
        }
        .alert(importCommandesFeedbackTitle, isPresented: $showImportCommandesFeedback) {
            Button("OK") {}
        } message: {
            Text(importCommandesFeedbackMessage)
        }
        .confirmationDialog("Importer depuis…", isPresented: $showImportImageSource, titleVisibility: .visible) {
            Button("Appareil photo") {
                showCamera = true
            }
            Button("Bibliothèque photo") {
                showPhotosPicker = true
            }
            Button("Annuler", role: .cancel) {}
        }
        .photosPicker(isPresented: $showPhotosPicker, selection: $selectedPhotoItem, matching: .images)
        .fullScreenCover(isPresented: $showCamera) {
            CameraImagePicker(image: $capturedImage)
                .ignoresSafeArea()
        }
        .onChange(of: capturedImage) {
            guard let img = capturedImage else { return }
            capturedImage = nil
            processOCRImage(img)
        }
        .onChange(of: selectedPhotoItem) {
            guard let item = selectedPhotoItem else { return }
            selectedPhotoItem = nil
            isProcessingOCR = true
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    processOCRImage(img)
                } else {
                    isProcessingOCR = false
                }
            }
        }


        .alert("Nouvelle campagne", isPresented: $showNouvelleCampagneRappel) {
            Button("Sauvegarder et continuer") {
                _ = store.sauvegarderCampagne(nom: store.titreCampagne)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showNouvelleCampagneOptions = true
                }
            }
            Button("Continuer sans sauvegarder", role: .destructive) {
                showNouvelleCampagneOptions = true
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("La campagne « \(store.titreCampagne) » n'a peut-être pas été sauvegardée. Voulez-vous la sauvegarder avant de tout effacer ?")
        }
        .confirmationDialog("Que faire des clients ?", isPresented: $showNouvelleCampagneOptions, titleVisibility: .visible) {
            Button("Tout effacer", role: .destructive) {
                store.nouvelleCampagne(garderClients: false)
            }
            Button("Garder les noms (vider commandes)") {
                store.nouvelleCampagne(garderClients: true)
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Voulez-vous conserver la liste des clients (noms et téléphones) pour la nouvelle campagne ?")
        }
    }

    // MARK: - Helpers

    private var fileImporterAllowedTypes: [UTType] {
        if fileImportJSON {
            return [.json]
        }
        return [.plainText, .commaSeparatedText, UTType(filenameExtension: "csv") ?? .commaSeparatedText, .pdf, .png, .jpeg, .image]
    }

    private var importCommandesFeedbackTitle: String {
        guard let r = importCommandesResult else { return "Import" }
        if !r.erreurs.isEmpty && r.lignesAjoutees == 0 && r.variantesCrees == 0 && r.prixImportes == 0 { return "Erreur d'import" }
        if r.variantesCrees > 0 || r.prixImportes > 0 {
            return "Campagne importée ✓"
        }
        return "\(r.lignesAjoutees) ligne\(r.lignesAjoutees > 1 ? "s" : "") importée\(r.lignesAjoutees > 1 ? "s" : "") ✓"
    }

    private var importCommandesFeedbackMessage: String {
        guard let r = importCommandesResult else { return "" }
        var parts: [String] = []
        if r.commandesCreees > 0 { parts.append("\(r.commandesCreees) nouvelle\(r.commandesCreees > 1 ? "s" : "") commande\(r.commandesCreees > 1 ? "s" : "")") }
        if r.lignesAjoutees > 0 { parts.append("\(r.lignesAjoutees) ligne\(r.lignesAjoutees > 1 ? "s" : "") de commande") }
        if r.variantesCrees > 0 { parts.append("\(r.variantesCrees) variante\(r.variantesCrees > 1 ? "s" : "") créée\(r.variantesCrees > 1 ? "s" : "")") }
        if r.prixImportes > 0 { parts.append("\(r.prixImportes) prix importé\(r.prixImportes > 1 ? "s" : "")") }
        if !r.erreurs.isEmpty { parts.append(r.erreurs.joined(separator: "\n")) }
        if !r.diagnosticIA.isEmpty { parts.append("[IA] \(r.diagnosticIA)") }
        return parts.isEmpty ? "Aucune donnée importée" : parts.joined(separator: "\n")
    }

    private func processOCRImage(_ image: UIImage) {
        isProcessingOCR = true
        store.importerCommandesDepuisImage(image) { result in
            isProcessingOCR = false
            importCommandesResult = result
            showImportCommandesFeedback = true
        }
    }

    // MARK: - Importer des campagnes

    private var importCampagnesSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "doc.badge.arrow.up")
                    .foregroundStyle(.seafoam)
                Text("Importer des campagnes")
                    .font(.headline)
                    .foregroundStyle(.seafoam)
                Spacer()
                if !storeManager.proUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Text("Importez des commandes depuis un fichier CSV, un PDF ou une photo. Les colonnes sont détectées automatiquement (Client, Variante, Taille, Couleur, Quantité…).")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Fichier (CSV, PDF, image)
            Button {
                fileImportJSON = false
                showFileImporter = true
            } label: {
                HStack {
                    Image(systemName: "doc.badge.arrow.up")
                    Text("Fichier (CSV, PDF, image…)")
                        .fontWeight(.medium)
                    Spacer()
                    if isProcessingOCR {
                        ProgressView()
                            .tint(.seafoam)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.seafoam.opacity(0.15))
                .foregroundStyle(.seafoamText)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isProcessingOCR)

            // Photo / Appareil photo
            Button {
                showImportImageSource = true
            } label: {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("Photo / Appareil photo")
                        .fontWeight(.medium)
                    Spacer()
                    if isProcessingOCR {
                        ProgressView()
                            .tint(.seafoam)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.seafoam.opacity(0.15))
                .foregroundStyle(.seafoamText)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isProcessingOCR)

            if isProcessingOCR {
                HStack(spacing: 8) {
                    ProgressView()
                    Text(AITriageService.shared.estConfigure
                         ? "Analyse intelligente en cours…"
                         : "Reconnaissance du texte en cours…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .disabled(!storeManager.proUnlocked)
        .opacity(storeManager.proUnlocked ? 1 : 0.5)
    }

    // MARK: - Configuration

    private var configSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "gearshape.2")
                    .foregroundStyle(.ocean)
                Text("Configuration")
                    .font(.headline)
                    .foregroundStyle(.ocean)
                Spacer()
            }

            Button {
                showCampagneSetup = true
            } label: {
                HStack {
                    Image(systemName: "gearshape.2")
                    Text("Configurer la campagne")
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(LinearGradient.oceanGradient)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
                if let url = store.exporterCampagneCSV() {
                    campagneCSVShareItem = IdentifiableURL(url: url)
                }
            } label: {
                HStack {
                    Image(systemName: "tablecells")
                    Text("Exporter la campagne (CSV)")
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(LinearGradient.oceanGradient)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(store.variantes.isEmpty)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Nouvelle campagne

    private var nouvelleCampagneSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.orange)
                Text("Nouvelle campagne")
                    .font(.headline)
                    .foregroundStyle(.orange)
                Spacer()
            }

            Text("Réinitialisez tout pour démarrer une nouvelle campagne. Vous pourrez choisir de conserver ou non la liste des clients.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                showNouvelleCampagneRappel = true
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Nouvelle campagne")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange.gradient)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Sauvegarde

    private var sauvegardeSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "externaldrive.fill")
                    .foregroundStyle(.ocean)
                Text("Sauvegarde campagne")
                    .font(.headline)
                    .foregroundStyle(.ocean)
                Spacer()
                if !storeManager.proUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Text("Sauvegardez ou restaurez l'intégralité de la campagne (commandes, réglements, variantes…) au format JSON.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                nomSauvegarde = store.titreCampagne
                showSauvegardeNom = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.down.on.square")
                    Text("Sauvegarder la campagne")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(LinearGradient.oceanGradient)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
                if let url = store.exporterCampagneJSON() {
                    shareItem = IdentifiableURL(url: url)
                }
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Partager le fichier JSON")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(LinearGradient.oceanGradient)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
                store.rafraichirListeCampagnes()
                showChargerCampagne = true
            } label: {
                HStack {
                    Image(systemName: "tray.and.arrow.down")
                    Text("Charger une sauvegarde")
                        .fontWeight(.medium)
                    if !store.campagnesSauvegardees.isEmpty {
                        Spacer()
                        Text("\(store.campagnesSauvegardees.count)")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.25))
                            .clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(LinearGradient.oceanGradient)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
                fileImportJSON = true
                showFileImporter = true
            } label: {
                HStack {
                    Image(systemName: "doc.badge.plus")
                    Text("Importer un fichier JSON")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(LinearGradient.oceanGradient)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .disabled(!storeManager.proUnlocked)
        .opacity(storeManager.proUnlocked ? 1 : 0.5)
    }
}

// MARK: - Liste des campagnes sauvegardées

struct CampagneListView: View {
    @ObservedObject var store: OrderStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmCharger: String? = nil
    @State private var confirmSupprimer: String? = nil

    var body: some View {
        NavigationStack {
            Group {
                if store.campagnesSauvegardees.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "externaldrive")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("Aucune sauvegarde")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Sauvegardez une campagne pour la retrouver ici.")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(store.campagnesSauvegardees, id: \.self) { nom in
                            Button {
                                confirmCharger = nom
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "doc.text.fill")
                                        .foregroundStyle(.ocean)
                                        .font(.title3)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(nom)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.primary)
                                        Text("Appuyer pour charger")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    confirmSupprimer = nom
                                } label: {
                                    Label("Supprimer", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Sauvegardes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .onAppear {
                store.rafraichirListeCampagnes()
            }
            .alert("Charger cette campagne ?", isPresented: Binding(
                get: { confirmCharger != nil },
                set: { if !$0 { confirmCharger = nil } }
            )) {
                Button("Charger", role: .destructive) {
                    if let nom = confirmCharger {
                        _ = store.chargerCampagne(nom: nom)
                        dismiss()
                    }
                }
                Button("Annuler", role: .cancel) { confirmCharger = nil }
            } message: {
                Text("La campagne actuelle sera remplacée par « \(confirmCharger ?? "") ». Pensez à sauvegarder avant si nécessaire.")
            }
            .alert("Supprimer cette sauvegarde ?", isPresented: Binding(
                get: { confirmSupprimer != nil },
                set: { if !$0 { confirmSupprimer = nil } }
            )) {
                Button("Supprimer", role: .destructive) {
                    if let nom = confirmSupprimer {
                        store.supprimerCampagne(nom: nom)
                    }
                }
                Button("Annuler", role: .cancel) { confirmSupprimer = nil }
            } message: {
                Text("La sauvegarde « \(confirmSupprimer ?? "") » sera définitivement supprimée.")
            }
        }
    }
}

// MARK: - Appareil photo

struct CameraImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraImagePicker
        init(_ parent: CameraImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
