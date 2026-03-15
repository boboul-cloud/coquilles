//
//  Order.swift
//  Groop
//
//  Created by Robert Oulhen on 11/03/2026.
//

import Foundation

enum UniteQuantite: String, Codable, CaseIterable {
    case kg = "kg"
    case unite = "unité(s)"
}

struct Variante: Identifiable, Codable, Hashable {
    var id = UUID()
    var nom: String = ""
    var prix: Double = 0
    var tailles: [String] = []
    var couleurs: [String] = []
}

enum ModePaiement: String, Codable, CaseIterable {
    case especes = "ESPÈCES"
    case cheque = "CHÈQUE"
}

struct Reglement: Identifiable, Codable {
    var id = UUID()
    var montant: Double
    var modePaiement: ModePaiement
    var date: Date = Date()
}

struct CategorieClient: Identifiable, Codable, Hashable {
    var id = UUID()
    var nom: String = ""
}

struct LigneCommande: Identifiable, Codable {
    var id = UUID()
    var variante: String = ""
    var taille: String? = nil
    var couleur: String? = nil
    var quantite: Double = 0
    var quantiteLivree: Double = 0

    func prix(variantes: [Variante]) -> Double? {
        variantes.first { $0.nom == variante }?.prix
    }

    func total(variantes: [Variante]) -> Double? {
        guard let p = prix(variantes: variantes) else { return nil }
        return quantite * p
    }

    func totalLivre(variantes: [Variante]) -> Double? {
        guard let p = prix(variantes: variantes) else { return nil }
        return quantiteLivree * p
    }

    var estLivree: Bool { quantite > 0 && quantiteLivree >= quantite }
    var resteALivrer: Double { max(0, quantite - quantiteLivree) }
}

struct Order: Identifiable, Codable {
    var id = UUID()
    var telephone: String = ""
    var prenom: String = ""
    var nom: String = ""
    var categorieID: UUID? = nil
    var lignes: [LigneCommande] = []
    var reglements: [Reglement] = []
    var dateLivraison: Date? = nil

    // Legacy fields kept for backward Codable compatibility
    var modePaiement: ModePaiement? = nil
    var impaye: Double = 0
    var impayeModePaiement: ModePaiement? = nil
    var livre: Bool = false
    var dateReglement: Date? = nil
    var dateReglementImpaye: Date? = nil

    /// Nom complet pour affichage (prénom + nom)
    var nomComplet: String {
        [prenom, nom].filter { !$0.isEmpty }.joined(separator: " ")
    }

    var quantiteTotale: Double {
        lignes.map(\.quantite).reduce(0, +)
    }

    var quantiteTotaleLivree: Double {
        lignes.map(\.quantiteLivree).reduce(0, +)
    }

    func total(variantes: [Variante]) -> Double? {
        let totals = lignes.compactMap { $0.total(variantes: variantes) }
        guard !totals.isEmpty else { return nil }
        return totals.reduce(0, +)
    }

    var totalRegle: Double {
        reglements.map(\.montant).reduce(0, +)
    }

    var estRegle: Bool {
        totalRegle > 0 || modePaiement != nil
    }

    func estEntierementRegle(variantes: [Variante]) -> Bool {
        guard let t = total(variantes: variantes), t > 0 else { return false }
        return totalRegle >= t
    }

    func resteARegler(variantes: [Variante]) -> Double {
        guard let t = total(variantes: variantes) else { return 0 }
        return max(0, t - totalRegle)
    }

    func montantPaye(variantes: [Variante]) -> Double? {
        if totalRegle > 0 { return totalRegle }
        guard modePaiement != nil, let t = total(variantes: variantes) else { return nil }
        return t
    }

    var estLivre: Bool {
        livre || (!lignes.isEmpty && lignes.allSatisfy { $0.estLivree })
    }

    var partiellementLivre: Bool {
        lignes.contains { $0.quantiteLivree > 0 } && !estLivre
    }

    var estValide: Bool {
        !nomComplet.isEmpty && !lignes.isEmpty && lignes.allSatisfy { !$0.variante.isEmpty && $0.quantite > 0 }
    }

    mutating func livrerTout() {
        dateLivraison = dateLivraison ?? Date()
        for i in lignes.indices {
            lignes[i].quantiteLivree = lignes[i].quantite
        }
        livre = true
    }

    mutating func livrerLigne(_ ligneID: UUID, quantite: Double) {
        guard let index = lignes.firstIndex(where: { $0.id == ligneID }) else { return }
        lignes[index].quantiteLivree = min(lignes[index].quantite, lignes[index].quantiteLivree + quantite)
        dateLivraison = dateLivraison ?? Date()
        if lignes.allSatisfy({ $0.estLivree }) {
            livre = true
        }
    }

    mutating func annulerLivraison() {
        for i in lignes.indices {
            lignes[i].quantiteLivree = 0
        }
        livre = false
        dateLivraison = nil
    }

    mutating func ajouterReglement(montant: Double, mode: ModePaiement) {
        reglements.append(Reglement(montant: montant, modePaiement: mode))
        dateReglement = Date()
    }

    mutating func supprimerReglement(_ id: UUID) {
        reglements.removeAll { $0.id == id }
        if reglements.isEmpty {
            dateReglement = nil
        }
    }

    mutating func reglerImpaye(par mode: ModePaiement) {
        if impaye > 0 {
            ajouterReglement(montant: impaye, mode: mode)
            impayeModePaiement = mode
            dateReglementImpaye = Date()
            impaye = 0
        }
    }

    mutating func remiseAZero() {
        lignes = []
        reglements = []
        modePaiement = nil
        impaye = 0
        impayeModePaiement = nil
        livre = false
        dateLivraison = nil
        dateReglement = nil
        dateReglementImpaye = nil
    }
}
