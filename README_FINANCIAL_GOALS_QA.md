Q&A pour la soutenance — Module "Financial Goals"

But
----
Fournir un fichier de questions-réponses (Q&A) prêt à l'emploi pour présenter le module "Financial Goals" devant un professeur ou un jury : questions techniques, réponses concises, références aux fichiers du projet et script de démonstration.

Plan / Checklist
- [x] Rassembler les questions probables qu’un enseignant peut poser.
- [x] Rédiger des réponses claires et courtes, avec références aux fichiers pertinents.
- [x] Ajouter un script de démonstration étape par étape et une checklist de préparation.
- [x] Sauvegarder dans `README_FINANCIAL_GOALS_QA.md` à la racine du projet.

Notes d'usage
- Ce document est en français et conçu pour être lu ou imprimé avant la soutenance.
- Chaque réponse contient une référence aux fichiers sources (chemins relatifs dans le projet) pour faciliter les preuves en direct.

Questions fréquentes et réponses préparées
-----------------------------------------
1) Quelle est l'architecture globale du module Goals ?
Réponse : Une architecture simple en couches : UI → façade en mémoire `GoalsData` (`lib/models/goals_data.dart`) → persistance `GoalDbService` (`lib/services/goal_db_service.dart`). Les services externes (taux de change, citations) sont encapsulés dans `ExchangeRateService` et `QuoteApiService`.

2) Où sont définis les modèles ?
Réponse : Dans `lib/models/goal_model.dart` : `Goal`, `Milestone`, `GoalTransaction`. Ils fournissent `toMap/fromMap`, `toJson/fromJson`, `copyWith` et des getters utiles (`progress`, `daysRemaining`, `dailySavingsNeeded`).

3) Comment est stockée la donnée en local ?
Réponse : SQLite via `sqflite`. Table `goals` définie dans `lib/services/goal_db_service.dart` ; colonnes pour titre/montants/etc. et une colonne `data` contenant le JSON complet du `Goal` pour sérialiser listes internes.

4) Pourquoi stocker le JSON complet dans `data` au lieu de tables relationnelles ?
Réponse : Simplicité et rapidité d'implémentation pour objets imbriqués (milestones, contributions). Trade-off : complexité pour requêtes partielles — compensé en stockant aussi colonnes utiles (target, current, createdAt).

5) Décrivez le flux CRUD complet.
Réponse :
- Create : `AddGoalDialog` → `GoalsData.addGoal(goal)` → `GoalDbService.insertGoal(goal)` → `GoalsData.load()`.
- Read : `GoalsData.load()` lit via `GoalDbService.fetchAllGoals()` et met à jour `GoalsData.goals`.
- Update : dialog d'édition → `GoalsData.updateGoal(updated)` → `GoalDbService.updateGoal(updated)` → reload.
- Delete : `GoalsData.deleteGoal(id)` → `GoalDbService.deleteGoal(id)` → reload.
- Contribution : `AddContributionDialog` → `GoalsData.addContribution(goalId, tx)` → `GoalDbService.addContribution(goalId, tx)` (atomise lecture, ajout transaction, update `current`).

6) L'opération `addContribution` est-elle atomique ?
Réponse : Non actuellement. `addContribution` lit la ligne, modifie l'objet et appelle `updateGoal`. Pour sécurité concurrente, on devrait utiliser `db.transaction(...)` pour garantir l'atomicité.

7) Comment gérez-vous les ids des goals ?
Réponse : Par défaut `AddGoalDialog` génère un id à partir de `DateTime.now().millisecondsSinceEpoch.toString()`. Le projet inclut aussi `uuid` dans `pubspec.yaml` si on souhaite IDs UUID.

8) Comment récupérez-vous les taux de change ?
Réponse : `lib/services/exchange_rate_service.dart` interroge successivement :
- `https://api.exchangerate.host/latest?base={BASE}&symbols={TARGET}`
- `https://api.frankfurter.app/latest?from={BASE}&to={TARGET}`
- `https://open.er-api.com/v6/latest/{BASE}`
Le premier provider qui répond correctement renvoie le taux. `ConvertedAmount` consomme `ExchangeRateService.convert()`.

9) Quelles APIs externes utilisez-vous plus précisément ?
Réponse :
- Taux : exchangerate.host, frankfurter.app, open.er-api.com.
- Citations : quotable.io, zenquotes.io, type.fit (via `QuoteApiService`).

10) Que se passe-t-il si toutes les APIs de taux échouent ?
Réponse : `ExchangeRateService.fetchRate` lance une exception après avoir essayé les providers. `ConvertedAmount` gère les erreurs en affichant uniquement le montant de base si la conversion échoue.

11) Comment fonctionne l'API de citations (Quote API) ?
Réponse : `lib/services/quote_api_service.dart` essaie plusieurs fournisseurs (quotable, zenquotes, type.fit), met la dernière citation réussie en cache dans `SharedPreferences` (`quote_api_last`) et renvoie le cache ou un fallback si tout échoue. `QuoteBanner` consomme `fetchThemedQuote('goals')`.

12) Comment partagez-vous les exports (CSV/XLSX/PDF) ?
Réponse : `lib/services/goal_export_service.dart` génère les fichiers (utilise `excel`, `pdf`, `path_provider`) et partage via `share_plus` (actuellement `Share.shareXFiles` utilisé — avertissement de dépréciation ; recommandé : `SharePlus.instance.share`).

13) Le module fonctionne-t-il en mode offline ?
Réponse : Oui. Toutes les opérations CRUD sont locales via SQLite. Seuls les services de conversion/citations nécessitent une connexion.

14) Comment tester ce module ?
Réponse :
- Unit tests : mocker `http.Client` (ex: `http_mock_adapter`), mocker `SharedPreferences` et utiliser `sqflite_common_ffi` pour tests DB hors device.
- Tests manuels : lancer l'app, créer goals, ajouter contributions, exporter et vérifier fichiers.

15) Quels sont les cas d'erreur principaux et leur gestion ?
Réponse :
- Erreurs réseau : fallback entre providers, cache pour les quotes.
- Erreurs DB : try/catch dans `GoalsData` (actuellement on ignore certaines exceptions ; améliorer en remontant erreurs à l'UI).
- Parsing JSON : implémentation defensive dans `fromMap` avec valeurs par défaut.

16) Quelles améliorations proposeriez-vous ?
Réponse :
- Ajouter transactions DB pour `addContribution`.
- Implémenter TTL pour le cache de citations et stratégie de backoff pour les APIs.
- Ajouter tests unitaires pour `GoalDbService` et `QuoteApiService`.
- Ajouter `onUpgrade` et migrations pour la DB.
- Remplacer `Share.shareXFiles` par `SharePlus.instance.share()` pour supprimer l'avertissement.

17) Comment gérer la synchronisation avec un backend ?
Réponse : Créer une stratégie de sync (push local → serveur, pull serveur → local), gérer conflits (last-write-wins ou versioning), utiliser une queue locale pour opérations hors-ligne et exécuter sync en tâche d'arrière-plan.

18) Que montrer en démonstration live ? (script recommandé)
Réponse :
- Ouvrir `Goals` (montrer `QuoteBanner`).
- Ajouter un goal via le dialogue (`lib/components/FinancialGoals/add_goal_dialog.dart`).
- Ouvrir la page détails (`GoalDetailsPage`) et ajouter une contribution (`add_contribution_dialog.dart`).
- Montrer l'export (CSV/Excel/PDF) via le menu et partager un fichier (`goal_export_service.dart`).
- Montrer `goal_db_service.dart` et expliquer `insert/update/addContribution`.

19) Comment prouver la couverture par les tests ?
Réponse : Présenter des tests unitaires existants ou ajouter rapidement un test qui vérifie `addContribution` avec `sqflite_common_ffi` (création d'une DB en mémoire), exécution et assertions.

20) Questions de sécurité / confidentialité ?
Réponse :
- Les données sensibles restent locales ; pour plus de sécurité on peut chiffrer la DB (SQLCipher) et restreindre le partage des exports.
- Ne pas activer `HttpHelper.allowBadCerts` en production.

21) Comment optimiser si l'utilisateur a 10k goals ?
Réponse :
- Éviter de recharger toute la table après chaque mutation ; appliquer modifications à la liste en mémoire et faire refresh périodique.
- Paginer / indexer colonnes pour recherche/tri.
- Utiliser requêtes SQL ciblées pour extraire sous-ensembles.

22) Exemple de test unitaire pour `addContribution` ?
Réponse (résumé) :
- Préparer une DB en mémoire avec un goal existant (current = 100).
- Appeler `GoalDbService.addContribution(goalId, tx)` avec `tx.amount = 50`.
- Lire le goal en DB et assert `current == 150` et `contributions` contient `tx`.

23) Pourquoi avoir un `GoalApiService` mock ?
Réponse : Séparer la logique locale/DB et la couche API pour faciliter le remplacement par un backend réel et tester l'UI sans serveur.

24) Comment documentez-vous le code ?
Réponse : Ce README et les commentaires dans les fichiers (voir `lib/models/goal_model.dart`, `lib/services/goal_db_service.dart`, `lib/services/exchange_rate_service.dart`). Le nouveau fichier `README_FINANCIAL_GOALS_QA.md` rassemble les questions et réponses pour la soutenance.

25) Derniers conseils pour la soutenance orale ?
Réponse :
- Soyez transparent sur les choix et leurs compromis.
- Montrez l'app en live en suivant le script de démonstration.
- Mentionnez rapidement les améliorations prévues et les tests que vous pouvez ajouter.

Checklist de préparation pour la soutenance
-------------------------------------------
- [ ] Ouvrir et avoir prêts à l'écran : `goal_model.dart`, `goal_db_service.dart`, `quote_api_service.dart`, `goal_export_service.dart`.
- [ ] Lancer l'app et vérifier : création de goal, ajout contribution, export PDF/CSV/XLSX, affichage `ConvertedAmount`.
- [ ] Préparer un slide avec le schéma DB (table `goals`) et le flux CRUD.
- [ ] Préparer réponses courtes pour questions de sécurité, tests et performances.

Fin du fichier Q&A.

