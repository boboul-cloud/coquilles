//
//  PlusCampagneView.swift
//  Groop
//
//  Sauvegarde, restauration et partage de campagnes.
//

import SwiftUI
import UniformTypeIdentifiers

struct PlusCampagneView: View {
    @ObservedObject var store: OrderStore
    @ObservedObject var storeManager: StoreManager

    @State private var shareItem: IdentifiableURL? = nil
    @State private var showSauvegardeNom = false
    @State private var nomSauvegarde = ""
    @State private var showChargerCampagne = false
    @State private var showImportJSON = false
    @State private var showSauvegardeFeedback = false
    @State private var showNouvelleCampagneRappel = false
    @State private var showNouvelleCampagneOptions = false
    @State private var showCampagneSetup = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                configSection
                nouvelleCampagneSection
                sauvegardeSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Campagne")
        .navigationBarTitleDisplayMode(.inline)
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
        .fileImporter(isPresented: $showImportJSON, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url):
                let accessing = url.startAccessingSecurityScopedResource()
                defer { if accessing { url.stopAccessingSecurityScopedResource() } }
                if store.chargerCampagne(depuis: url) {
                    showSauvegardeFeedback = true
                    nomSauvegarde = store.titreCampagne
                }
            case .failure:
                break
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
                .background(Color(.systemGray6))
                .foregroundStyle(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
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
                .background(Color.ocean.opacity(0.1))
                .foregroundStyle(.ocean)
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
                            .foregroundStyle(.ocean)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.ocean.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .foregroundStyle(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
                showImportJSON = true
            } label: {
                HStack {
                    Image(systemName: "doc.badge.plus")
                    Text("Importer un fichier JSON")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .foregroundStyle(.primary)
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
