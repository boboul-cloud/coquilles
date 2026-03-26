//
//  PlusExportationView.swift
//  Groop
//
//  Export PDF, bons de commande et fiches de distribution.
//

import SwiftUI
import QuickLook
import UniformTypeIdentifiers

struct PlusExportationView: View {
    @ObservedObject var store: OrderStore
    @ObservedObject var storeManager: StoreManager

    @State private var shareItem: IdentifiableURL? = nil
    @State private var previewURL: URL? = nil
    @State private var showExportFeedback = false
    @State private var showConfirmFinie = false
    @State private var showProUpgrade = false
    @State private var showImportClients = false
    @State private var importClientsCount = 0
    @State private var showImportClientsFeedback = false
    @State private var exportClientsShareItem: IdentifiableURL? = nil
    @State private var showExportFormat = false
    @State private var showExportCategoryPicker = false
    @State private var pendingExportSeparer = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if !storeManager.proUnlocked {
                    proRequiredBanner
                }
                finalisationSection
                exportSection
                importExportSection
                bonCommandeSection
                distributionSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Exportation")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $shareItem) { item in
            ShareSheet(activityItems: [item.url])
        }
        .quickLookPreview($previewURL)
        .alert("Générer le récapitulatif final ?", isPresented: $showConfirmFinie) {
            Button("Générer et partager") {
                if let url = store.exporterRecapitulatif() {
                    shareItem = IdentifiableURL(url: url)
                }
            }
            Button("Annuler", role: .cancel) {}
        }
        .sheet(isPresented: $showProUpgrade) {
            GroopProView(storeManager: storeManager)
        }
        .fileImporter(isPresented: $showImportClients, allowedContentTypes: [.plainText, .commaSeparatedText]) { result in
            switch result {
            case .success(let url):
                let accessing = url.startAccessingSecurityScopedResource()
                defer { if accessing { url.stopAccessingSecurityScopedResource() } }
                importClientsCount = store.importerClientsDepuisFichier(url: url)
                if importClientsCount > 0 {
                    showImportClientsFeedback = true
                }
            case .failure:
                break
            }
        }
        .alert("\(importClientsCount) client\(importClientsCount > 1 ? "s" : "") importé\(importClientsCount > 1 ? "s" : "") ✓", isPresented: $showImportClientsFeedback) {
            Button("OK") {}
        }
        .sheet(item: $exportClientsShareItem) { item in
            ShareSheet(activityItems: [item.url])
        }
        .confirmationDialog("Format d'export", isPresented: $showExportFormat, titleVisibility: .visible) {
            Button("Nom ; Téléphone ; Catégorie") {
                pendingExportSeparer = false
                if store.categories.count > 1 {
                    showExportCategoryPicker = true
                } else {
                    if let url = store.exporterClientsFichier(separerNomPrenom: false) {
                        exportClientsShareItem = IdentifiableURL(url: url)
                    }
                }
            }
            Button("Prénom ; Nom ; Téléphone (Temps de Jeu)") {
                pendingExportSeparer = true
                if store.categories.count > 1 {
                    showExportCategoryPicker = true
                } else {
                    let catID = store.categories.first?.id
                    if let url = store.exporterClientsFichier(separerNomPrenom: true, categorieID: catID) {
                        exportClientsShareItem = IdentifiableURL(url: url)
                    }
                }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Choisissez le format selon l'application de destination.")
        }
        .confirmationDialog("Quelle catégorie exporter ?", isPresented: $showExportCategoryPicker, titleVisibility: .visible) {
            Button("Toutes les catégories") {
                if pendingExportSeparer {
                    if let url = store.exporterClientsFichier(separerNomPrenom: true) {
                        exportClientsShareItem = IdentifiableURL(url: url)
                    }
                } else {
                    if let url = store.exporterClientsFichier(separerNomPrenom: false) {
                        exportClientsShareItem = IdentifiableURL(url: url)
                    }
                }
            }
            ForEach(store.categories) { cat in
                Button(cat.nom) {
                    if let url = store.exporterClientsFichier(separerNomPrenom: pendingExportSeparer, categorieID: cat.id) {
                        exportClientsShareItem = IdentifiableURL(url: url)
                    }
                }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Choisissez la catégorie à exporter ou exportez tout.")
        }
    }

    // MARK: - Bannière Pro requise

    private var proRequiredBanner: some View {
        Button {
            showProUpgrade = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Fonctionnalité Pro")
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text("Débloquez Groop Pro pour exporter vos documents.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Finalisation

    @ViewBuilder
    private var finalisationSection: some View {
        if store.toutEstFini {
            VStack(spacing: 12) {
                Image(systemName: "party.popper.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.seafoam)
                    .symbolEffect(.bounce.up, value: true)

                Text("Toutes les commandes sont finalisées !")
                    .font(.headline)
                    .foregroundStyle(.seafoam)
                    .multilineTextAlignment(.center)

                Button {
                    showConfirmFinie = true
                } label: {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                        Text("Générer le récapitulatif final")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.seafoam.gradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding()
            .background(Color.seafoam.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }

    // MARK: - Export PDF

    private var exportSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "doc.richtext")
                    .foregroundStyle(.ocean)
                Text("Export PDF")
                    .font(.headline)
                    .foregroundStyle(.ocean)
                Spacer()
                if !storeManager.proUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Button {
                if let url = store.exporterRecapitulatif() {
                    previewURL = url
                }
            } label: {
                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
                    Text("Consulter le récapitulatif")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.ocean.opacity(0.1))
                .foregroundStyle(.oceanText)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
                if let url = store.exporterRecapitulatif() {
                    shareItem = IdentifiableURL(url: url)
                    showExportFeedback = true
                }
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Partager le récapitulatif")
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

    // MARK: - Import/Export clients

    private var importExportSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(.ocean)
                Text("Import/Export")
                    .font(.headline)
                    .foregroundStyle(.ocean)
                Spacer()
                if !storeManager.proUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Text("Temps de jeu")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                showImportClients = true
            } label: {
                HStack {
                    Image(systemName: "person.crop.circle.badge.plus")
                    Text("Importer une liste de clients")
                        .fontWeight(.medium)
                    Spacer()
                    if !storeManager.proUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.ocean.opacity(0.1))
                .foregroundStyle(.oceanText)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!storeManager.proUnlocked)
            .opacity(storeManager.proUnlocked ? 1 : 0.5)

            Button {
                showExportFormat = true
            } label: {
                HStack {
                    Image(systemName: "person.crop.circle.badge.arrow.right")
                    Text("Exporter la liste de clients")
                        .fontWeight(.medium)
                    Spacer()
                    if !storeManager.proUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    } else {
                        Text("\(store.orders.filter { !$0.nomComplet.isEmpty }.count)")
                            .font(.caption)
                            .foregroundStyle(.oceanText)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.ocean.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.ocean.opacity(0.1))
                .foregroundStyle(.oceanText)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!storeManager.proUnlocked || store.orders.isEmpty)
            .opacity(storeManager.proUnlocked ? 1 : 0.5)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Bon de commande

    private var bonCommandeSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "list.clipboard.fill")
                    .foregroundStyle(.ocean)
                Text("Bon de commande")
                    .font(.headline)
                    .foregroundStyle(.ocean)
                Spacer()
                if !storeManager.proUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Text("Regroupe toutes les commandes par variante, taille et couleur")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            BonCommandeButton(
                icon: "doc.text.magnifyingglass",
                label: "Détaillé (prix + clients)",
                style: .outline
            ) {
                if let url = store.exporterBonCommande(afficherPrix: true, afficherClients: true) {
                    previewURL = url
                }
            }

            BonCommandeButton(
                icon: "eurosign.circle",
                label: "Avec prix, sans clients",
                style: .outline
            ) {
                if let url = store.exporterBonCommande(afficherPrix: true, afficherClients: false) {
                    previewURL = url
                }
            }

            BonCommandeButton(
                icon: "shippingbox",
                label: "Fournisseur (quantités seules)",
                style: .outline
            ) {
                if let url = store.exporterBonCommande(afficherPrix: false, afficherClients: false) {
                    previewURL = url
                }
            }

            BonCommandeButton(
                icon: "tablecells",
                label: "Export CSV (Excel)",
                style: .filled
            ) {
                if let url = store.exporterBonCommandeCSV() {
                    shareItem = IdentifiableURL(url: url)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .disabled(!storeManager.proUnlocked)
        .opacity(storeManager.proUnlocked ? 1 : 0.5)
    }

    // MARK: - Distribution

    private var distributionSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "truck.box.fill")
                    .foregroundStyle(.ocean)
                Text("Fiche de distribution")
                    .font(.headline)
                    .foregroundStyle(.ocean)
                Spacer()
                if !storeManager.proUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Text("Liste par catégorie et par client pour la distribution, avec cases à cocher")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            BonCommandeButton(
                icon: "doc.text.magnifyingglass",
                label: "Consulter",
                style: .outline
            ) {
                if let url = store.exporterDistribution() {
                    previewURL = url
                }
            }

            BonCommandeButton(
                icon: "square.and.arrow.up",
                label: "Partager",
                style: .filled
            ) {
                if let url = store.exporterDistribution() {
                    shareItem = IdentifiableURL(url: url)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .disabled(!storeManager.proUnlocked)
        .opacity(storeManager.proUnlocked ? 1 : 0.5)
    }
}

// MARK: - Bouton bon de commande

struct BonCommandeButton: View {
    enum Style { case outline, filled }

    let icon: String
    let label: String
    var style: Style = .outline
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(label)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(style == .filled ? AnyShapeStyle(LinearGradient.seaGradient) : AnyShapeStyle(Color.ocean.opacity(0.1)))
            .foregroundStyle(style == .filled ? .white : .oceanText)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
