# Coquilles — App Privacy Details (Apple)

Ce document correspond aux informations à remplir dans la section
**« App Privacy »** d'App Store Connect.

---

## Collecte de données : NON

> **« Est-ce que vous ou vos partenaires tiers collectez des données à partir de cette application ? »**
>
> **Réponse : Non**

Coquilles ne collecte aucune donnée. Toutes les informations saisies par
l'utilisateur (noms, numéros de téléphone, commandes, paiements) sont
stockées **localement sur l'appareil** via UserDefaults et le système de
fichiers (Documents/). Aucune donnée n'est transmise à un serveur, un
service d'analyse ou un tiers.

---

## Détail par catégorie Apple

| Catégorie Apple             | Collecté ? | Raison             |
|-----------------------------|------------|--------------------|
| Coordonnées                 | ❌ Non      | —                  |
| Santé et forme              | ❌ Non      | —                  |
| Données financières         | ❌ Non      | —                  |
| Localisation                | ❌ Non      | —                  |
| Informations sensibles      | ❌ Non      | —                  |
| Contacts                    | ❌ Non      | —                  |
| Contenu utilisateur         | ❌ Non      | —                  |
| Historique de navigation    | ❌ Non      | —                  |
| Historique de recherche     | ❌ Non      | —                  |
| Identifiants                | ❌ Non      | —                  |
| Achats                      | ❌ Non      | —                  |
| Données d'utilisation       | ❌ Non      | —                  |
| Diagnostics                 | ❌ Non      | —                  |
| Autre                       | ❌ Non      | —                  |

---

## Frameworks utilisés et impact sur la vie privée

| Framework        | Données transmises | Notes                                    |
|------------------|--------------------|------------------------------------------|
| SwiftUI / UIKit  | Aucune             | UI locale uniquement                     |
| MessageUI (SMS)  | Aucune par l'app   | L'envoi passe par l'app Messages native ; Coquilles n'a pas accès au résultat de l'envoi |
| QuickLook        | Aucune             | Prévisualisation locale de PDF           |
| FileManager      | Aucune             | Lecture/écriture locale uniquement       |
| UserDefaults     | Aucune             | Stockage local sur l'appareil            |

---

## Autorisations système requises

| Permission iOS | Requise ? | Raison                                         |
|----------------|-----------|------------------------------------------------|
| Réseau         | ❌ Non     | Aucune requête réseau                          |
| Localisation   | ❌ Non     | —                                              |
| Caméra         | ❌ Non     | —                                              |
| Microphone     | ❌ Non     | —                                              |
| Photos         | ❌ Non     | —                                              |
| Contacts       | ❌ Non     | —                                              |
| Notifications  | ❌ Non     | —                                              |

---

## Résumé pour App Store Connect

Lorsque vous remplissez la section App Privacy :

1. **Sélectionnez « No » à la question « Do you or your third-party partners collect data from this app? »**
2. C'est tout — aucune autre déclaration n'est nécessaire.

L'étiquette de confidentialité affichée sur l'App Store sera :
> **🏷️ Aucune donnée collectée**
