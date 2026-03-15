//
//  coquillesApp.swift
//  Groop
//
//  Created by Robert Oulhen on 11/03/2026.
//

import SwiftUI

@main
struct GroopApp: App {
    @StateObject private var store = OrderStore()
    @StateObject private var storeManager = StoreManager()
    @State private var showImportConfirm = false
    @State private var importedName = ""

    var body: some Scene {
        WindowGroup {
            ContentView(store: store, storeManager: storeManager)
                .tint(.ocean)
                .onOpenURL { url in
                    if let name = store.importerCommandeDepuisURL(url) {
                        importedName = name
                        showImportConfirm = true
                    }
                }
                .alert("Commande importée ✓", isPresented: $showImportConfirm) {
                    Button("OK") {}
                } message: {
                    Text("La commande de « \(importedName) » a été ajoutée.")
                }
        }
    }
}
