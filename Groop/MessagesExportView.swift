//
//  MessagesExportView.swift
//  Groop
//
//  Page « Plus » – navigation vers les sous-sections.
//

import SwiftUI

struct MessagesExportView: View {
    @ObservedObject var store: OrderStore
    @ObservedObject var storeManager: StoreManager
    @State private var showProUpgrade = false

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Groop Pro
                Section {
                    if !storeManager.proUnlocked {
                        Button {
                            showProUpgrade = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "star.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.orange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Groop Pro")
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.primary)
                                    Text("Débloquer toutes les fonctionnalités")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        Button {
                            showProUpgrade = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "crown.fill")
                                    .font(.title2)
                                    .foregroundStyle(LinearGradient(
                                        colors: [.orange, .yellow],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                Text("Groop Pro")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text("Activé")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.seafoam)
                            }
                        }
                    }

                    Button {
                        Task { await storeManager.restore() }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.ocean)
                            Text("Restaurer les achats")
                                .foregroundStyle(.primary)
                        }
                    }
                }

                Section {
                NavigationLink {
                    PlusExportationView(store: store, storeManager: storeManager)
                } label: {
                    Label {
                        Text("Exportation")
                    } icon: {
                        Image(systemName: "doc.richtext")
                            .foregroundStyle(.ocean)
                    }
                }

                NavigationLink {
                    PlusCommandeView(store: store)
                } label: {
                    Label {
                        Text("Commande")
                    } icon: {
                        Image(systemName: "message.fill")
                            .foregroundStyle(.ocean)
                    }
                }

                NavigationLink {
                    PlusCampagneView(store: store, storeManager: storeManager)
                } label: {
                    Label {
                        Text("Campagne")
                    } icon: {
                        Image(systemName: "externaldrive.fill")
                            .foregroundStyle(.ocean)
                    }
                }

                NavigationLink {
                    PlusReglageView(store: store, storeManager: storeManager)
                } label: {
                    Label {
                        Text("Réglages")
                    } icon: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(.ocean)
                    }
                }
                }
            }
            .navigationTitle("Plus")
            .sheet(isPresented: $showProUpgrade) {
                GroopProView(storeManager: storeManager)
            }
        }
    }
}
