# Groop — Guide de soumission App Store

## Checklist avant soumission

### 1. Dans Xcode

- [ ] **Bundle Identifier** : vérifier qu'il correspond à celui créé dans App Store Connect (ex: `com.robertoulhen.groop`)
- [ ] **Version** : 1.0
- [ ] **Build** : 1
- [ ] **Deployment Target** : iOS 17.0 (minimum recommandé pour les API SwiftUI utilisées)
- [ ] **Device** : iPhone + iPad
- [ ] **Icône d'app** : placer une icône 1024×1024 dans `Assets.xcassets/AppIcon`
- [ ] **Launch Screen** : configuré (storyboard ou SwiftUI)
- [ ] **Archive** : Product → Archive, puis Distribute App → App Store Connect

### 2. Dans App Store Connect

#### Informations de l'app
- [ ] Nom : **Groop**
- [ ] Sous-titre : **Commandes groupées faciles**
- [ ] Catégorie : **Utilitaires** / **Économie et entreprise**
- [ ] Évaluation du contenu : **4+**

#### Version 1.0
- [ ] Coller la **description** depuis `AppStore/metadata.md`
- [ ] Coller le **texte promotionnel** depuis `AppStore/metadata.md`
- [ ] Coller les **mots-clés** depuis `AppStore/metadata.md`
- [ ] Coller le texte **Quoi de neuf** depuis `AppStore/metadata.md`
- [ ] URL de support : `https://boboul-cloud.github.io/groop/support.html`
- [ ] URL de confidentialité : `https://boboul-cloud.github.io/groop/confidentialite.html`

#### Captures d'écran requises
- [ ] **iPhone 6.7"** (iPhone 15 Pro Max) : 1290 × 2796 px — minimum 3, max 10
- [ ] **iPhone 6.5"** (iPhone 11 Pro Max) : 1242 × 2688 px — minimum 3, max 10

> **Conseil** : Prenez des captures des 4 écrans principaux :
> 1. Tableau de bord avec des données d'exemple
> 2. Liste des commandes
> 3. Page des paiements
> 4. Page Plus (menu)
> Ajoutez éventuellement : export PDF, page web de commande

#### App Privacy
- [ ] Sélectionner **« No, we do not collect data »**
- [ ] Voir `AppStore/privacy-details.md` pour le détail

#### Review Notes (notes pour l'examinateur Apple)
Coller le texte suivant :

```
Groop is a local-only group order management app. All data is stored on-device (UserDefaults + local JSON files). No server, no account, no analytics.

The SMS feature uses MFMessageComposeViewController (native iOS). The app does not access message results.

The "Web order page" feature generates a URL pointing to a static HTML page hosted on GitHub Pages. The page encodes product data in the URL fragment (base64). Customer orders are submitted via SMS (sms: link) — no server is involved.

No login is required. The app works entirely offline.
```

### 3. Après soumission

- [ ] Vérifier le statut dans App Store Connect (« Waiting for Review » → « In Review » → « Ready for Sale »)
- [ ] S'assurer que les pages GitHub Pages fonctionnent :
  - https://boboul-cloud.github.io/groop/confidentialite.html
  - https://boboul-cloud.github.io/groop/conditions.html
  - https://boboul-cloud.github.io/groop/support.html

---

## Structure des fichiers créés

```
AppStore/
├── metadata.md          ← Description, mots-clés, texte promotionnel
├── privacy-details.md   ← Détails confidentialité pour App Store Connect
└── submission-guide.md  ← Ce fichier (checklist)

docs/
├── index.html           ← Page web de commande (existante)
├── confidentialite.html ← Politique de confidentialité
├── conditions.html      ← Conditions d'utilisation
└── support.html         ← Page de support / FAQ
```
