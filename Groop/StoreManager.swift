//
//  StoreManager.swift
//  Groop
//
//  Gestion de l'achat intégré « Groop Pro » via StoreKit 2.
//

import Combine
import StoreKit
import SwiftUI

@MainActor
final class StoreManager: ObservableObject {
    nonisolated static let proProductID = "com.groop.pro"

    @Published private(set) var proUnlocked = false
    @Published private(set) var product: Product?
    @Published private(set) var purchaseInProgress = false
    @Published private(set) var loadError = false

    private var transactionListener: Task<Void, Never>?

    init() {
        transactionListener = listenForTransactions()
        Task { [weak self] in await self?.loadProduct() }
        Task { [weak self] in await self?.refreshPurchaseStatus() }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Chargement du produit

    func loadProduct() async {
        loadError = false
        do {
            let products = try await Product.products(for: [Self.proProductID])
            print("[StoreKit] Produits chargés : \(products.map(\.id))")
            product = products.first
            if let p = product {
                print("[StoreKit] Produit trouvé : \(p.displayName) — \(p.displayPrice)")
            } else {
                print("[StoreKit] Aucun produit trouvé pour '\(Self.proProductID)'")
                loadError = true
            }
        } catch {
            print("[StoreKit] Erreur chargement : \(error)")
            loadError = true
        }
    }

    // MARK: - Achat

    func purchase() async {
        guard let product, !purchaseInProgress else { return }
        purchaseInProgress = true
        defer { purchaseInProgress = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if let transaction = try? verification.payloadValue {
                    await transaction.finish()
                    proUnlocked = true
                }
            case .userCancelled:
                break
            case .pending:
                break
            @unknown default:
                break
            }
        } catch {
            // Échec de l'achat
        }
    }

    // MARK: - Restaurer les achats

    func restore() async {
        try? await AppStore.sync()
        await refreshPurchaseStatus()
    }

    // MARK: - Vérification du statut

    func refreshPurchaseStatus() async {
        for await result in Transaction.currentEntitlements {
            if let transaction = try? result.payloadValue,
               transaction.productID == Self.proProductID {
                proUnlocked = true
                return
            }
        }
    }

    // MARK: - Écoute des transactions

    private func listenForTransactions() -> Task<Void, Never> {
        let productID = Self.proProductID
        return Task.detached { [weak self] in
            for await result in Transaction.updates {
                if let transaction = try? result.payloadValue {
                    await transaction.finish()
                    if transaction.productID == productID {
                        await MainActor.run { [weak self] in
                            self?.proUnlocked = true
                        }
                    }
                }
            }
        }
    }

    // MARK: - Limites version gratuite

    nonisolated static let maxClientsGratuit = 15

    var peutAjouterClient: Bool {
        proUnlocked
    }

    func clientsLimiteAtteinte(count: Int) -> Bool {
        !proUnlocked && count >= Self.maxClientsGratuit
    }
}
