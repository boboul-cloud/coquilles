//
//  AITriageService.swift
//  Groop
//
//  Service de triage IA pour les PDFs complexes (catalogues, tarifs pro, etc.).
//  Utilise l'API OpenAI pour nettoyer le texte brut extrait des PDFs :
//  reconnaître les produits, ignorer titres/TVA/en-têtes.
//

import Foundation

/// Résultat structuré du triage IA : liste de produits extraits.
struct ProduitIA {
    var nom: String
    var taille: String   // volume/poids (25cl, 1L, 5kg…), vide si absent
    var couleur: String  // contenant/conditionnement (Bouteille, Bidon, Bag in Box…), vide si absent
    var prix: Double     // 0 si non trouvé
}

/// Service de triage IA qui nettoie le texte brut extrait des PDFs complexes
/// en identifiant les lignes produit et en éliminant le bruit (titres, TVA, etc.).
class AITriageService {

    static let shared = AITriageService()
    private init() {}

    /// Clé API OpenAI stockée dans UserDefaults
    var cleAPI: String {
        get { UserDefaults.standard.string(forKey: "openAICleAPI") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "openAICleAPI") }
    }

    /// Vérifie si le service IA est configuré (clé API présente)
    var estConfigure: Bool {
        !cleAPI.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Triage principal

    /// Envoie le texte brut extrait d'un PDF à l'IA pour triage.
    /// Retourne une liste de produits extraits, ou nil en cas d'erreur / aucun produit.
    func trierTexte(_ texteBrut: String, completion: @escaping ([ProduitIA]?) -> Void) {
        guard estConfigure else {
            completion(nil)
            return
        }

        // Limiter le texte envoyé (max ~12000 caractères pour couvrir plus de pages)
        let texteEnvoye = texteBrut.count > 12000 ? String(texteBrut.prefix(12000)) : texteBrut

        let systemPrompt = [
            "Tu es un extracteur de catalogues produits professionnels.",
            "",
            "Tu recois le texte brut issu d'un OCR sur un PDF de tarifs.",
            "Le texte est organise en LIGNES ou les colonnes sont separees par des points-virgules (;).",
            "Chaque ligne represente une rangee du tableau original du PDF.",
            "",
            "ATTENTION : les colonnes du PDF source varient. Voici des colonnes courantes :",
            "- Designation / Produit / Article",
            "- Contenance / Volume (25cl, 50cl, 75cl, 100cl, 3L...)",
            "- Conditionnement / Contenant (Bouteille, Bidon, Bag in Box, Cubi, Fontaine, Fut...)",
            "- Prix HT / Prix unitaire / P.U. HT (nombre comme 7,85 ou 12,40)",
            "- Prix TTC (souvent = Prix HT x (1 + TVA))",
            "- Taux TVA (5,50% ou 20,00% - CE N'EST PAS UN PRIX)",
            "- Code article / Reference (chiffres longs comme 3760xxx - A IGNORER)",
            "",
            "Ta mission : pour chaque ligne produit, extraire et SEPARER les informations dans ce format :",
            "NOM;VOLUME;CONTENANT;PRIX_HT",
            "",
            "Regles STRICTES :",
            "1. NOM = le nom commercial du produit uniquement.",
            "   Exemples : Intense AOP Bio, Fruite Vert, Cepes, Truffe, Vin Blanc, Vin Rose.",
            "   NE PAS inclure le volume, le contenant, le prix ou la TVA dans le nom.",
            "2. VOLUME = la contenance : 10cl, 15cl, 20cl, 25cl, 50cl, 75cl, 100cl, 3L, 5L, etc.",
            "   Si absent, laisser vide.",
            "3. CONTENANT = Bouteille, Bidon, Bag in Box, Cubi, Fontaine, Fut, Cannette, etc.",
            "   Si absent, laisser vide.",
            "4. PRIX_HT = le prix HT unitaire comme nombre decimal avec POINT. Ex: 7.85, 12.40",
            "   - Convertir la virgule decimale en point : 7,85 devient 7.85",
            "   - NE PAS confondre avec le taux de TVA (5,50% n'est PAS un prix).",
            "   - NE PAS prendre le prix TTC si le HT est disponible.",
            "   - Si aucun prix, mettre 0.",
            "5. Une ligne par combinaison produit + volume + contenant.",
            "   Le NOM doit etre identique entre les lignes du meme produit.",
            "6. IGNORER :",
            "   - Titres de sections en majuscules (ex: INTENSE AOP Provence, COFFRETS DECOUVERTE, VINS)",
            "   - En-tetes de colonnes (ex: Designation;Contenance;Conditionnement;Prix HT;TVA)",
            "   - Lignes avec uniquement un taux TVA (5,50%)",
            "   - Codes article longs (3760...), codes-barres",
            "   - Totaux, sous-totaux, remises, frais de port",
            "   - Mentions legales, adresses, telephones, numeros de page",
            "7. NE PAS mettre de ligne d'en-tete. NE PAS ajouter de texte explicatif.",
            "8. Si aucun produit, repondre : AUCUN_PRODUIT",
            "",
            "EXEMPLE D'INPUT OCR :",
            "INTENSE AOP Provence - CERTIFIEE BIO",
            "Intense AOP Bio;25cl;Bouteille;7,85;5,50%",
            "3760xxx;Intense AOP Bio;25cl;Bidon;7,40;5,50%",
            "Intense AOP Bio;50cl;Bouteille;12,85;5,50%",
            "FRUITE VERT",
            "Fruite Vert;25cl;Bouteille;6,50;5,50%",
            "",
            "SORTIE ATTENDUE :",
            "Intense AOP Bio;25cl;Bouteille;7.85",
            "Intense AOP Bio;25cl;Bidon;7.40",
            "Intense AOP Bio;50cl;Bouteille;12.85",
            "Fruite Vert;25cl;Bouteille;6.50",
        ].joined(separator: "\n")

        let userMessage = "Texte brut du PDF (OCR avec colonnes separees par ;) :\n\n\(texteEnvoye)"

        // Log pour debug
        logDebug("=== INPUT ENVOYE A L'IA ===\n\(texteEnvoye)\n=== FIN INPUT ===")

        dernierDiagnostic = "Appel en cours..."
        appelAPI(system: systemPrompt, user: userMessage) { reponse in
            guard let reponse = reponse else {
                self.logDebug("=== IA : AUCUNE REPONSE === diagnostic: \(self.dernierDiagnostic)")
                completion(nil)
                return
            }

            self.logDebug("=== REPONSE IA ===\n\(reponse)\n=== FIN REPONSE ===")

            let nettoye = reponse.trimmingCharacters(in: .whitespacesAndNewlines)
            if nettoye == "AUCUN_PRODUIT" || nettoye.isEmpty {
                self.dernierDiagnostic = "IA: aucun produit trouve"
                completion(nil)
                return
            }

            // Parser la réponse CSV en ProduitIA
            let produits = self.parserReponseCSV(nettoye)
            if produits.isEmpty {
                self.dernierDiagnostic = "IA: parsing CSV echoue"
                self.logDebug("=== PARSING ECHOUE === reponse brute:\n\(reponse)")
            } else {
                let avecPrix = produits.filter { $0.prix > 0 }.count
                let avecTaille = produits.filter { !$0.taille.isEmpty }.count
                let avecCouleur = produits.filter { !$0.couleur.isEmpty }.count
                self.dernierDiagnostic = "IA: \(produits.count) produits (\(avecPrix) prix, \(avecTaille) tailles, \(avecCouleur) contenants)"
                self.logDebug("=== PRODUITS PARSES === \(produits.count) total, \(avecPrix) avec prix, \(avecTaille) avec taille, \(avecCouleur) avec couleur")
                for (i, p) in produits.prefix(10).enumerated() {
                    self.logDebug("  [\(i)] nom=\(p.nom) | taille=\(p.taille) | couleur=\(p.couleur) | prix=\(p.prix)")
                }
            }
            completion(produits.isEmpty ? nil : produits)
        }
    }

    // MARK: - Parser la réponse IA

    /// Parse le CSV renvoyé par l'IA (NOM;VOLUME;CONTENANT;PRIX) en liste de ProduitIA.
    private func parserReponseCSV(_ csv: String) -> [ProduitIA] {
        var produits: [ProduitIA] = []

        let lignes = csv.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        for ligne in lignes {
            // Ignorer les lignes qui ressemblent à un en-tête, du markdown ou du texte libre
            let low = ligne.lowercased()
            if low.hasPrefix("nom") || low.hasPrefix("variante") || low.hasPrefix("produit") ||
               low.hasPrefix("```") || low.hasPrefix("---") || low.hasPrefix("designation") ||
               low.hasPrefix("désignation") || low.hasPrefix("|") {
                continue
            }

            let parts = ligne.components(separatedBy: ";")
            guard parts.count >= 1 else { continue }

            func clean(_ s: String) -> String {
                s.trimmingCharacters(in: .whitespacesAndNewlines)
                 .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
            }

            let nom = clean(parts[0])
            guard !nom.isEmpty, nom.count >= 2 else { continue }
            // Ignorer les noms qui ne sont qu'un prix ou un taux TVA
            if nom.range(of: #"^\d+[.,]\d{1,2}\s*[€%]?$"#, options: .regularExpression) != nil { continue }

            let taille = parts.count >= 2 ? clean(parts[1]) : ""
            let couleur = parts.count >= 3 ? clean(parts[2]) : ""

            var prix: Double = 0
            if parts.count >= 4 {
                let prixStr = clean(parts[3])
                    .replacingOccurrences(of: ",", with: ".")
                    .replacingOccurrences(of: "€", with: "")
                    .replacingOccurrences(of: "$", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                prix = Double(prixStr) ?? 0
            } else if parts.count == 3 {
                // Fallback : si l'IA n'a renvoyé que 3 colonnes (NOM;TAILLE;PRIX)
                let prixStr = clean(parts[2])
                    .replacingOccurrences(of: ",", with: ".")
                    .replacingOccurrences(of: "€", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if let p = Double(prixStr) {
                    prix = p
                }
            }

            // Ignorer les lignes avec un prix qui ressemble à un taux TVA (ex: 5.50, 20.0)
            // Heuristique : si le prix est un taux TVA courant ET le nom est très court
            // on ne filtre pas ici, le prompt devrait gérer

            produits.append(ProduitIA(nom: nom, taille: taille, couleur: couleur, prix: prix))
        }

        return produits
    }

    // MARK: - Appel API OpenAI

    /// Dernier diagnostic de l'appel API (pour affichage à l'utilisateur)
    var dernierDiagnostic: String = ""

    private func appelAPI(system: String, user: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            dernierDiagnostic = "URL API invalide"
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(cleAPI)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60

        let body: [String: Any] = [
            "model": "gpt-4o",
            "temperature": 0.0,
            "max_tokens": 4000,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": user]
            ]
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            dernierDiagnostic = "Erreur encodage JSON"
            logDebug("=== ERREUR : impossible d'encoder le body JSON ===")
            completion(nil)
            return
        }
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { data, response, error in
            // Vérifier les erreurs réseau
            if let error = error {
                let msg = "Erreur reseau : \(error.localizedDescription)"
                self.logDebug("=== ERREUR API === \(msg)")
                DispatchQueue.main.async {
                    self.dernierDiagnostic = msg
                    completion(nil)
                }
                return
            }

            // Vérifier le code HTTP
            let httpStatus = (response as? HTTPURLResponse)?.statusCode ?? 0
            self.logDebug("=== HTTP STATUS : \(httpStatus) ===")

            guard let data = data else {
                let msg = "Aucune donnee recue (HTTP \(httpStatus))"
                self.logDebug("=== ERREUR API === \(msg)")
                DispatchQueue.main.async {
                    self.dernierDiagnostic = msg
                    completion(nil)
                }
                return
            }

            // Tenter de parser le JSON
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                let raw = String(data: data.prefix(500), encoding: .utf8) ?? "(binaire)"
                let msg = "Reponse non-JSON (HTTP \(httpStatus)) : \(raw)"
                self.logDebug("=== ERREUR API === \(msg)")
                DispatchQueue.main.async {
                    self.dernierDiagnostic = msg
                    completion(nil)
                }
                return
            }

            // Vérifier si l'API retourne une erreur
            if let apiError = json["error"] as? [String: Any] {
                let errorMsg = apiError["message"] as? String ?? "erreur inconnue"
                let errorType = apiError["type"] as? String ?? ""
                let msg = "Erreur OpenAI (\(errorType)) : \(errorMsg)"
                self.logDebug("=== ERREUR API === \(msg)")
                DispatchQueue.main.async {
                    self.dernierDiagnostic = msg
                    completion(nil)
                }
                return
            }

            // Extraire le contenu de la réponse
            guard let choices = json["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String
            else {
                let msg = "Format reponse inattendu (HTTP \(httpStatus))"
                self.logDebug("=== ERREUR API === \(msg) json=\(json)")
                DispatchQueue.main.async {
                    self.dernierDiagnostic = msg
                    completion(nil)
                }
                return
            }

            self.logDebug("=== SUCCES API === \(content.count) caracteres recus")
            DispatchQueue.main.async {
                self.dernierDiagnostic = "OK (\(content.count) car.)"
                completion(content)
            }
        }.resume()
    }

    // MARK: - Debug log

    /// Ecrit un log de debug dans Documents/ai_debug.txt (pour diagnostiquer les imports).
    func logDebug(_ message: String) {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let logURL = docs.appendingPathComponent("ai_debug.txt")
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)
        let entry = "[\(timestamp)] \(message)\n\n"
        if FileManager.default.fileExists(atPath: logURL.path) {
            if let handle = try? FileHandle(forWritingTo: logURL) {
                handle.seekToEndOfFile()
                if let data = entry.data(using: .utf8) {
                    handle.write(data)
                }
                handle.closeFile()
            }
        } else {
            try? entry.data(using: .utf8)?.write(to: logURL)
        }
    }
}
