//
//  GroopProView.swift
//  Groop
//
//  Écran de mise à niveau vers Groop Pro.
//

import StoreKit
import SwiftUI

struct GroopProView: View {
    @ObservedObject var storeManager: StoreManager
    @Environment(\.dismiss) private var dismiss
    @State private var showCongrats = false

    var body: some View {
        NavigationStack {
            ScrollView {
                if showCongrats || storeManager.proUnlocked {
                    // MARK: - Écran Félicitations
                    VStack(spacing: 24) {
                        VStack(spacing: 12) {
                            Image(systemName: "party.popper.fill")
                                .font(.system(size: 64))
                                .foregroundStyle(LinearGradient(
                                    colors: [.orange, .yellow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))

                            Text("Félicitations !")
                                .font(.largeTitle)
                                .fontWeight(.bold)

                            Text("Groop Pro est débloqué.\nProfitez de toutes les fonctionnalités !")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)

                        VStack(spacing: 0) {
                            avantageRowUnlocked(icon: "person.3.fill", color: .ocean,
                                                titre: "Clients illimités")
                            Divider().padding(.leading, 52)
                            avantageRowUnlocked(icon: "externaldrive.fill", color: .seafoam,
                                                titre: "Sauvegarde de campagnes")
                            Divider().padding(.leading, 52)
                            avantageRowUnlocked(icon: "doc.richtext", color: .oceanLight,
                                                titre: "Export PDF & fichiers")
                            Divider().padding(.leading, 52)
                            avantageRowUnlocked(icon: "person.crop.circle.badge.plus", color: .coral,
                                                titre: "Import de clients")
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))

                        Button {
                            dismiss()
                        } label: {
                            Text("C'est parti !")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(LinearGradient(
                                    colors: [.orange, .yellow.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .orange.opacity(0.3), radius: 8, y: 4)
                        }
                    }
                    .padding()
                } else {
                VStack(spacing: 24) {
                    // MARK: - Header
                    VStack(spacing: 12) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(LinearGradient(
                                colors: [.orange, .yellow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))

                        Text("Groop Pro")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)

                        Text("Débloquez toutes les fonctionnalités\npour gérer vos commandes sans limites.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

                    // MARK: - Avantages
                    VStack(spacing: 0) {
                        avantageRow(icon: "person.3.fill", color: .ocean,
                                    titre: "Clients illimités",
                                    detail: "Version gratuite : \(StoreManager.maxClientsGratuit) clients max")
                        Divider().padding(.leading, 52)
                        avantageRow(icon: "externaldrive.fill", color: .seafoam,
                                    titre: "Sauvegarde de campagnes",
                                    detail: "Sauvegardez et restaurez vos campagnes")
                        Divider().padding(.leading, 52)
                        avantageRow(icon: "doc.richtext", color: .oceanLight,
                                    titre: "Export PDF & fichiers",
                                    detail: "Récapitulatifs, bons de commande, listes")
                        Divider().padding(.leading, 52)
                        avantageRow(icon: "person.crop.circle.badge.plus", color: .coral,
                                    titre: "Import de clients",
                                    detail: "Importez vos listes depuis un fichier")
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                    // MARK: - Prix et achat
                    VStack(spacing: 12) {
                        if let product = storeManager.product {
                            Text("Achat unique")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Button {
                                Task {
                                    await storeManager.purchase()
                                    if storeManager.proUnlocked {
                                        showCongrats = true
                                    }
                                }
                            } label: {
                                HStack {
                                    if storeManager.purchaseInProgress {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text("Débloquer pour \(product.displayPrice)")
                                            .fontWeight(.bold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(LinearGradient(
                                    colors: [.orange, .yellow.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .orange.opacity(0.3), radius: 8, y: 4)
                            }
                            .disabled(storeManager.purchaseInProgress)
                        } else if storeManager.loadError {
                            VStack(spacing: 8) {
                                Text("Produit indisponible")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Button("Réessayer") {
                                    Task { await storeManager.loadProduct() }
                                }
                                .font(.subheadline)
                                .foregroundStyle(.ocean)
                            }
                        } else {
                            ProgressView("Chargement…")
                        }

                        Button {
                            Task { await storeManager.restore() }
                        } label: {
                            Text("Restaurer l'achat")
                                .font(.subheadline)
                                .foregroundStyle(.ocean)
                        }
                    }

                    // MARK: - Gratuit
                    VStack(spacing: 8) {
                        Text("Version gratuite")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        Text("1 campagne • \(StoreManager.maxClientsGratuit) clients • Commandes & paiements • Page web & SMS")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)
                }
                .padding()
                } // fin else
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .interactiveDismissDisabled(showCongrats)
        }
    }

    private func avantageRow(icon: String, color: Color, titre: String, detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(titre)
                    .fontWeight(.medium)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.seafoam)
        }
        .padding(.vertical, 10)
    }

    private func avantageRowUnlocked(icon: String, color: Color, titre: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32)
            Text(titre)
                .fontWeight(.medium)
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.seafoam)
        }
        .padding(.vertical, 10)
    }
}
