# Module FinancialGoals — Documentation

Ce document décrit le fonctionnement du module "FinancialGoals" dans l'application : modèles de données, persistance, services API simulés, composants UI et flux de navigation. Il sert à aider les développeurs à comprendre, étendre et intégrer ce module.

---

## Table des matières

- Vue d'ensemble
- Contrat (inputs/outputs) et formes de données
- Modèles principaux
- Persistance locale
- Service API (mock)
- Composants UI (liste et rôle)
- Pages et navigation
- Opérations CRUD (contrat et exemples)
- Cas limites / Edge cases
- Remplacement par SharedPreferences / Hive / Backend
- Tests manuels et commandes utiles
- Prochaines améliorations recommandées

---

## Vue d'ensemble

Le module FinancialGoals permet à un utilisateur de :
- Créer, lire, modifier et supprimer des objectifs financiers (goals).
- Ajouter des contributions (transactions) à un objectif.
- Voir la progression, les jalons (milestones) et des recommandations d'épargne.

Architecture :
- Modèles : `lib/models/goal_model.dart`
- Stockage & gestion : `lib/models/goals_data.dart`
- Service API simulé : `lib/services/goal_api_service.dart`
- UI composants : `lib/components/FinancialGoals/*`
- Pages : `lib/pages/goals_page.dart`, `lib/pages/goal_details_page.dart`

---

## Contrat (inputs/outputs)

- Input principal : création / édition d'un Goal via un formulaire (title, category, target, deadline, priority, description, emoji).
- Output : objet `Goal` (voir forme JSON ci-dessous) sauvegardé en local et utilisé par l'UI.

Success criteria :
- CRUD complet fonctionnel (les changements sont persistés localement).
- UI réactive et navigation fluide entre liste / détails / dialog de création.

Erreurs documentées :
- Entrées invalides du formulaire (montant non numérique, champs requis manquants) => messages de validation côté UI.
- Persistance : si l'écriture locale échoue, le module attrape l'erreur et continue avec les données en mémoire (log/IGNORED pour l'instant).

---

## Modèles principaux

Fichier : `lib/models/goal_model.dart`

Objet Goal (extrait) :

- id: String
- title: String
- category: String
- target: double
- current: double
- deadline: String (format YYYY-MM-DD)
- createdAt: DateTime
- priority: String (low|medium|high)
- description: String
- emoji: String
- milestones: List<Milestone>
- contributions: List<GoalTransaction>
- isCompleted: bool
- isArchived: bool

Méthodes utilitaires exposées sur `Goal` :
- `progress` : pourcentage atteint (0..100)
- `daysRemaining` : jours restants jusqu'à la date limite (0 si dépassé)
- `dailySavingsNeeded` : montant moyen journalier à épargner pour atteindre l'objectif avant la deadline
- `toMap()` / `fromMap()` / `toJson()` / `fromJson()` pour sérialisation

Forme JSON d'un Goal (exemple) :

{
  "id": "1",
  "title": "New Laptop",
  "category": "Electronics",
  "target": 1200.0,
  "current": 800.0,
  "deadline": "2025-12-31",
  "createdAt": "2025-01-01T00:00:00.000",
  "priority": "high",
  "description": "MacBook Air",
  "emoji": "💻",
  "milestones": [ ... ],
  "contributions": [ ... ],
  "isCompleted": false,
  "isArchived": false
}

---

## Persistance locale

Actuellement, la logique de persistence est dans : `lib/models/goals_data.dart`.

- Implémentation actuelle : fichier JSON local (`goals_data.json`) via `dart:io`. C'est volontaire pour éviter une dépendance externe dans l'état actuel du dépôt. Le fichier est lu au démarrage par `GoalsData.load()` et sauvegardé après chaque modification (add/update/delete/addContribution).

- Remarques techniques :
  - Sur mobile, l'accès au chemin courant peut nécessiter des adaptations (ex : `path_provider` pour obtenir le répertoire correct sur Android/iOS). Pour production, préférez `SharedPreferences`, `Hive` ou une DB locale (Sqflite).
  - La méthode `load()` charge les données persistées si elles existent, sinon elle insère un jeu de données par défaut et l'enregistre.

---

## Service API (mock)

Fichier : `lib/services/goal_api_service.dart`

- Fournit des méthodes asynchrones simulées (fetchGoals, createGoal, updateGoal, deleteGoal, addContribution) qui introduisent une latence artificielle et renvoient les objets passés.
- Objectif : faciliter l'intégration future d'un backend réel en gardant la couche service séparée.

---

## Composants UI

Tous les composants se trouvent sous `lib/components/FinancialGoals/` :

- `add_goal_dialog.dart` : formulaire pour créer (ou éditer si réutilisé) un Goal.
- `add_contribution_dialog.dart` : dialog pour ajouter une contribution (montant + note).
- `active_goals_tab.dart` : liste des goals actifs (intègre tri / filtre, et affiche `EnhancedGoalCard`).
- `completed_goals_tab.dart` : liste des goals complétés.
- `enhanced_goal_card.dart` : carte riche qui présente chaque objectif (progress bar, boutons action).
- `completed_goal_card.dart` : version adaptée pour les objectifs complétés.
- `savings_projection_card.dart` : calcule et présente la recommandation d'épargne (utilise `dailySavingsNeeded`).
- `quick_stats_card.dart`, `progress_chart_card.dart`, `smart_suggestions_card.dart`, `motivational_card.dart`, ... : widgets additionnels d'affichage et insights.

Conseils UX/Accessibilité :
- Les dialogs sont centrés et limités en largeur pour une lecture facile.
- Les boutons ont des labels explicites et toasts (SnackBar) sur succès.

---

## Pages & navigation

- `lib/pages/goals_page.dart` : page principale de gestion des objectifs. Contient des filtres, des onglets (Active / Completed), bouton + pour créer.
- `lib/pages/goal_details_page.dart` : page de détails d'un goal. Permet d'ajouter une contribution, éditer (ouvre `AddGoalDialog` pré-rempli) et supprimer.
- `profile_page.dart` ouvre `GoalsPage` via Navigator.

Flux usuel :
1. L'utilisateur ouvre `GoalsPage`.
2. Tape sur `+` -> `AddGoalDialog` -> Save -> `GoalsData.addGoal()` -> persist.
3. Liste se rafraîchit automatiquement (via setState / reload de GoalsData).
4. Tap sur un goal -> `GoalDetailsPage` -> voir contributions -> ajouter contribution -> `GoalsData.addContribution()` -> persist.

---

## Opérations CRUD — contrat détaillé

Create: `GoalsData.addGoal(Goal goal)`
- Entrée : objet `Goal` (id unique string). Le module sauvegarde en local.
- Sortie : Future<void> (persisté)

Read: `GoalsData.goals` (en mémoire) et `GoalsData.load()` pour recharger depuis le stockage.

Update: `GoalsData.updateGoal(Goal updatedGoal)`
- Trouve par `id`, remplace et enregistre.

Delete: `GoalsData.deleteGoal(String id)`
- Supprime et enregistre.

Add contribution: `GoalsData.addContribution(String goalId, GoalTransaction transaction)`
- Met à jour la liste des contributions du goal et incrémente `current`.

---

## Cas limites & tests à effectuer

- Créer un goal avec target = 0 ou target négatif : UI devrait valider pour éviter ça. (Actuellement validation empêche champs vides ou non numériques mais ne bloque pas zéros; pensez à ajouter validation > 0).
- deadline antérieure à la date actuelle : daysRemaining = 0 et dailySavingsNeeded renvoie remaining (besoin immédiat) — affichez un warning à l'utilisateur.
- Échec d'écriture sur disque : la méthode `save()` attrape l'erreur et ignore; envisagez d'ajouter une stratégie de retry ou afficher un message d'erreur.
- Concurrent writes (rare sur mobile) : gestion simple — dernières modifications gagnent. Pour usages multi-device, remontez vers un backend.

Tests manuels rapides :
- Lancer l'app, créer un goal, vérifier `goals_data.json` (ou la mémoire) et que la liste montre le goal.
- Ajouter une contribution et vérifier que `current` et `progress` s'actualisent.

---

## Remplacement par SharedPreferences / Hive (guide rapide)

Si vous voulez remplacer la persistance fichier par `SharedPreferences` :

1. Ajouter la dépendance dans `pubspec.yaml` :

```yaml
dependencies:
  shared_preferences: ^2.2.0
```

2. Exécuter :

```cmd
flutter pub get
```

3. Dans `lib/models/goals_data.dart`, remplacez la lecture/écriture fichier par :

- Lecture :
```dart
final prefs = await SharedPreferences.getInstance();
final raw = prefs.getString(_storageKey);
if (raw != null) { ... }
```
- Écriture :
```dart
await prefs.setString(_storageKey, encoded);
```

4. (Optionnel) Pour un stockage plus structuré et performant, utilisez `hive` (supporte objets, box, adaptateurs). Pour des besoins multi-user/offline robustes, Hive est recommandé.

---

## Commandes utiles (Windows - cmd.exe)

- Installer dépendances (si vous modifiez `pubspec.yaml`) :

```cmd
cd "F:\ESPRIT\Mobile\Mobile_Project_BrainStack_5SAE5"
flutter pub get
```

- Lancer l'application sur l'émulateur ou device connecté :

```cmd
flutter run
```

- Analyser les erreurs statiques (Dart analyzer) :

```cmd
flutter analyze
```

---

## Prochaines améliorations suggérées

- Remplacer la persistance fichier par `shared_preferences` ou `hive` (production mobile).
- Ajouter tests unitaires pour `GoalsData` (CRUD, sérialisation).
- Implémenter l'édition complète du goal en pré-remplissant `AddGoalDialog` et améliorer la validation.
- Ajouter animations / micro-interactions pour une UX plus fluide (Hero, transitions, progress animations).
- Ajouter synchronisation backend (auth + endpoints) via `GoalApiService` et gestion des conflits.

---

Si vous voulez, je peux :
- Basculer la persistance vers `SharedPreferences` directement et ajuster le code (je modifierai `goals_data.dart` et `pubspec.yaml`).
- Écrire quelques tests unitaires pour `GoalsData`.
- Ajouter un guide de contribution et un README plus synthétique pour les développeurs.

Dites-moi quelle action vous voulez que je fasse ensuite et je l'exécuterai.

