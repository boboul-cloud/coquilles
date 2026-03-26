//
//  PlusReglageView.swift
//  Groop
//
//  Configuration, remise à zéro et import de clients.
//

import SwiftUI
import UniformTypeIdentifiers

struct PlusReglageView: View {
    @ObservedObject var store: OrderStore
    @ObservedObject var storeManager: StoreManager

    @State private var showConfirmReset = false
    @State private var showModeEmploi = false
    @State private var showSauvegardeFeedback = false
    @State private var restaureMessage = ""
    @State private var showRestaureFeedback = false
    @State private var showConfirmRestaure: BackupInfo? = nil
    @State private var cleAPIOpenAI: String = AITriageService.shared.cleAPI

    private let confidentialiteURL = URL(string: "https://boboul-cloud.github.io/groop/confidentialite.html")!
    private let conditionsURL = URL(string: "https://boboul-cloud.github.io/groop/conditions.html")!

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                modeEmploiSection
                reglagesSection
                iaSection
                backupsSection
                confidentialiteSection
                versionSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Réglages")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Remise à zéro", isPresented: $showConfirmReset) {
            Button("Confirmer", role: .destructive) {
                store.remiseAZero()
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Toutes les commandes seront effacées. Les noms et téléphones des clients seront conservés.")
        }
        .alert("Sauvegarde effectuée ✓", isPresented: $showSauvegardeFeedback) {
            Button("OK") {}
        } message: {
            Text(restaureMessage)
        }
        .alert("Restaurer cette sauvegarde ?", isPresented: Binding(
            get: { showConfirmRestaure != nil },
            set: { if !$0 { showConfirmRestaure = nil } }
        )) {
            Button("Restaurer", role: .destructive) {
                if let info = showConfirmRestaure {
                    let count = store.restaurerBackup(info: info)
                    if count > 0 {
                        restaureMessage = "\(count) campagne\(count > 1 ? "s" : "") restaurée\(count > 1 ? "s" : "") depuis la sauvegarde du \(info.dateFormatee)."
                        showRestaureFeedback = true
                    }
                }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            if let info = showConfirmRestaure {
                Text("La campagne active et toutes les sauvegardes seront remplacées par celles du \(info.dateFormatee).")
            }
        }
        .alert("Restauration effectuée ✓", isPresented: $showRestaureFeedback) {
            Button("OK") {}
        } message: {
            Text(restaureMessage)
        }

    }

    // MARK: - Réglages

    private var modeEmploiSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "book.fill")
                    .foregroundStyle(.ocean)
                Text("Aide")
                    .font(.headline)
                    .foregroundStyle(.ocean)
                Spacer()
            }

            NavigationLink {
                ModeEmploiView()
            } label: {
                HStack {
                    Image(systemName: "questionmark.circle")
                    Text("Mode d'emploi")
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.ocean.opacity(0.1))
                .foregroundStyle(.oceanText)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Réglages (import/export/reset)

    private var reglagesSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "gearshape.fill")
                    .foregroundStyle(.ocean)
                Text("Réglages")
                    .font(.headline)
                    .foregroundStyle(.ocean)
                Spacer()
            }

            Button {
                if store.sauvegarderToutesCampagnes() != nil {
                    let dateStr = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short)
                    restaureMessage = "Sauvegarde créée le \(dateStr)."
                    showSauvegardeFeedback = true
                }
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("Sauvegarder l'état des campagnes")
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.ocean.opacity(0.1))
                .foregroundStyle(.oceanText)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
                showConfirmReset = true
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Remise à zéro")
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.coral.opacity(0.1))
                .foregroundStyle(.coral)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }


        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Intelligence Artificielle

    private var iaSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "brain")
                    .foregroundStyle(.ocean)
                Text("Import intelligent (IA)")
                    .font(.headline)
                    .foregroundStyle(.ocean)
                Spacer()
                if AITriageService.shared.estConfigure {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                }
            }

            Text("Pour les PDFs complexes (catalogues, tarifs pro…), l'IA reconnaît automatiquement les produits et ignore les titres, TVA, en-têtes, etc. Nécessite une clé API OpenAI.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 8) {
                SecureField("Clé API OpenAI (sk-…)", text: $cleAPIOpenAI)
                    .textContentType(.password)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .onChange(of: cleAPIOpenAI) {
                        AITriageService.shared.cleAPI = cleAPIOpenAI
                    }

                if cleAPIOpenAI.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                            .font(.caption2)
                        Text("Obtenez une clé sur platform.openai.com")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle")
                            .font(.caption2)
                            .foregroundStyle(.green)
                        Text("IA activée — les PDFs complexes seront analysés automatiquement")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Sauvegardes

    private var backupsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(.ocean)
                Text("Sauvegardes")
                    .font(.headline)
                    .foregroundStyle(.ocean)
                Spacer()
            }

            if store.backups.isEmpty {
                Text("Aucune sauvegarde")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(store.backups) { backup in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(backup.dateFormatee)
                                .fontWeight(.medium)
                                .font(.subheadline)
                        }
                        Spacer()
                        Button {
                            showConfirmRestaure = backup
                        } label: {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.ocean)
                        }
                        Button {
                            store.supprimerBackup(info: backup)
                        } label: {
                            Image(systemName: "trash.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.coral)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .onAppear { store.rafraichirListeBackups() }
    }

    // MARK: - Confidentialité et conditions

    private var confidentialiteSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "hand.raised.fill")
                    .foregroundStyle(.ocean)
                Text("Confidentialité et conditions")
                    .font(.headline)
                    .foregroundStyle(.ocean)
                Spacer()
            }

            Link(destination: confidentialiteURL) {
                HStack {
                    Image(systemName: "lock.shield")
                    Text("Politique de confidentialité")
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .foregroundStyle(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Link(destination: conditionsURL) {
                HStack {
                    Image(systemName: "doc.text")
                    Text("Conditions d'utilisation")
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
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

    // MARK: - Version et copyright

    private var versionSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.ocean)
                Text("À propos")
                    .font(.headline)
                    .foregroundStyle(.ocean)
                Spacer()
            }

            VStack(spacing: 8) {
                HStack {
                    Text("Version")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(appVersion) (\(buildNumber))")
                        .fontWeight(.medium)
                }

                Divider()

                HStack {
                    Text("Développeur")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Robert Oulhen")
                        .fontWeight(.medium)
                }

                Divider()

                Text("© \(Calendar.current.component(.year, from: Date())) Robert Oulhen. Tous droits réservés.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
