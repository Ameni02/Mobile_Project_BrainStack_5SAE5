README - Module Financial Goals (Détails techniques)

But
----
Ce document décrit en détail l'implémentation du module "Financial Goals" (objectifs financiers) présent dans ce projet Flutter : bibliothèques utilisées, base de données, APIs externes, flux d'intégration (CRUD), et explication complète du code (modèles, services, composants UI, export).

Checklist (ce que couvre ce document)
- Liste des packages Dart/Flutter utilisés par ce module (avec versions présentes dans `pubspec.yaml`).
- Base de données : schéma SQLite et comportement (persist/lecture/mise à jour/suppression).
- APIs externes : noms, URLs et rôle (taux de change). Mention du service d'API de goals (mock local).
- Flux CRUD complet (où sont appelées les méthodes, en mémoire vs DB).
- Explication détaillée des fichiers-clés (modèles, services, composants UI, export).
- Comment tester / exporter / partager les données.

Dépendances principales (liées au module Financial Goals)
------------------------------------------------------
Les dépendances listées ici proviennent de `pubspec.yaml` et sont utilisées par ou utiles au module :

- flutter (SDK)
- intl: ^0.19.0 — formatage des dates et montants.
- http: ^0.13.6 — requêtes HTTP (utilisé par `ExchangeRateService`).
- sqflite: ^2.2.8 — stockage SQLite (implémentation persistante des goals via `GoalDbService`).
- path: ^1.8.3 — manipulation de chemins (utilisé dans `goal_db_service.dart`).
- path_provider: ^2.1.5 — accès au répertoire de l'application (export de fichiers).
- share_plus: ^12.0.1 — partager les fichiers exportés.
- excel: ^4.0.6 — génération de fichiers XLSX (export Excel).
- pdf: ^3.11.3 — génération PDF (export PDF).
- cross_file: ^0.3.5 — types de fichiers multiplateformes (utilisé indirectement par share).
- uuid: ^4.5.2 — génération d'IDs si nécessaire (présente dans pubspec, utilisée possiblement).
- printing: ^5.14.2 — (présent dans pubspec) peut servir pour l'impression PDF, pas nécessairement utilisé dans le module d'export actuel.

Remarque : d'autres packages du projet peuvent être présents mais non directement utilisés par Financial Goals (ex: fl_chart, shared_preferences). Les versions ci-dessus reflètent le `pubspec.yaml` actuel.

Architecture et fichiers-clés
----------------------------
- Modèles :
  - `lib/models/goal_model.dart`
    - Classes : `Goal`, `Milestone`, `GoalTransaction`.
    - Méthodes importantes : `toMap()`, `fromMap()`, `toJson()`, `fromJson()`, `copyWith()`, `progress (getter)`, `daysRemaining`, `dailySavingsNeeded()`.

- Store en mémoire :
  - `lib/models/goals_data.dart` (classe statique `GoalsData`)
    - Contient la liste en mémoire `GoalsData.goals`.
    - Méthodes statiques pour `load()`, `save()`, `addGoal()`, `updateGoal()`, `deleteGoal()`, `addContribution()`.
    - `load()` et autres méthodes délèguent la persistance à `GoalDbService`.

- Persistance (SQLite) :
  - `lib/services/goal_db_service.dart` (`GoalDbService`)
    - Singleton : `GoalDbService.instance`.
    - Base : fichier `goals.db` (emplacement via `getDatabasesPath()`).
    - Schéma (table `goals`) :
      - id TEXT PRIMARY KEY
      - title TEXT NOT NULL
      - category TEXT
      - target REAL NOT NULL
      - current REAL NOT NULL
      - deadline TEXT
      - createdAt TEXT
      - priority TEXT
      - description TEXT
      - emoji TEXT
      - data TEXT NOT NULL  // JSON complet du Goal
    - Méthodes :
      - `fetchAllGoals()` : SELECT * FROM goals ORDER BY createdAt DESC ; convertit `data` JSON en `Goal`.
      - `insertGoal(Goal)` : INSERT avec `ConflictAlgorithm.replace` (donc upsert semantics).
      - `updateGoal(Goal)` : UPDATE WHERE id = ?
      - `deleteGoal(String id)` : DELETE WHERE id = ?
      - `addContribution(String goalId, GoalTransaction tx)` : lit le row, décodes JSON, ajoute contribution, met à jour `current` et appelle `updateGoal(updated)`.

- API (mock et réelles) :
  - `lib/services/goal_api_service.dart` : service d'API simulée (mock). Fournit des méthodes `fetchGoals()`, `createGoal()`, `updateGoal()`, `deleteGoal()`, `addContribution()` — actuellement elles ne font que simuler une latence et retourner les données entrantes. Aucune integration réseau réel pour les goals (les goals sont persistés localement via SQLite).

  - `lib/services/exchange_rate_service.dart` : service réel pour récupérer des taux de change. Il interroge plusieurs fournisseurs en cascade (fallback) :
    1. https://api.exchangerate.host/latest?base={BASE}&symbols={TARGET}
    2. https://api.frankfurter.app/latest?from={BASE}&to={TARGET}
    3. https://open.er-api.com/v6/latest/{BASE}

    - Comportement : `fetchRate(base, target)` essaye chaque provider séquentiellement ; le premier qui renvoie un taux valable est retourné. Si aucun ne répond, lève une exception.
    - `convert(amount, from, to)` multiplie `amount` par le taux récupéré (la méthode retourne immédiatement la valeur si les devises sont identiques).
    - Utilise `lib/services/http_helper.dart` pour créer un `http.Client` configurable (option `allowBadCerts` pour debug).

- UI (pages et composants) :
  - `lib/pages/goals_page.dart` : écran principal qui affiche deux onglets (Active, Completed), permet rafraîchir, ajouter un goal et exporter (CSV/Excel/PDF).
  - `lib/pages/goal_details_page.dart` : page détail d'un goal, montre progression, liste des contributions, actions (éditer, supprimer, partager résumé), bouton flottant pour ajouter contribution.
  - Composants `lib/components/FinancialGoals/*` :
    - `add_goal_dialog.dart` : formulaire pour créer/éditer un goal.
    - `add_contribution_dialog.dart` : dialog pour ajouter une contribution (montant+note).
    - `active_goals_tab.dart`, `completed_goals_tab.dart` : affichages par onglet.
    - `enhanced_goal_card.dart` : carte UI pour chaque goal (aperçu, progress bar, actions rapides).
    - `converted_amount.dart` (dans `components/finance`) : widget affichant le montant en devise locale et les conversions; il appelle `ExchangeRateService.convert()`.

- Export :
  - `lib/services/goal_export_service.dart` : export CSV/Excel/PDF et partage via `share_plus`.
    - `exportCsv(List<Goal>)` : construit un CSV (header + lignes), écrit dans `getApplicationDocumentsDirectory()`.
    - `exportExcel(List<Goal>)` : crée un workbook Excel via `excel` package et écrit les lignes.
    - `exportPdf(List<Goal>)` : utilise `pdf` package pour générer un PDF tabulaire.
    - `shareFile(File)` : partage le fichier via `Share.shareXFiles()`.

Flux CRUD (end-to-end)
----------------------
1. Create (Créer un goal)
   - UI : l'utilisateur ouvre `AddGoalDialog` (depuis `GoalsPage`) et soumet le formulaire.
   - Front : `AddGoalDialog` construit un objet `Goal` (id = timestamp par défaut, createdAt = now).
   - Persistance : appelle `widget.onSave(newGoal)` qui, dans `GoalsPage`, invoque `GoalsData.addGoal(goal)`.
   - `GoalsData.addGoal` appelle `GoalDbService.instance.insertGoal(goal)` pour persister en SQLite puis recharge la liste mémoire via `fetchAllGoals()`.

2. Read (Lire les goals)
   - Au démarrage de la page `GoalsPage.initState()`, `GoalsData.load()` est appelé.
   - `GoalsData.load()` appelle `GoalDbService.instance.fetchAllGoals()` et remplit `GoalsData.goals`.
   - Toutes les vues (Active/Completed tabs, cartes, détails) lisent depuis `GoalsData.goals`.

3. Update (Mettre à jour un goal)
   - UI : bouton Edit dans `GoalDetailsPage` ouvre un dialog d'édition (implémentation dans `GoalDetailsPage._showEditDialog`).
   - Après validation, `GoalsData.updateGoal(updated)` est appelé.
   - `GoalDbService.updateGoal(updated)` exécute un UPDATE sur la table `goals` et met à jour la colonne `data` (JSON complet).
   - `GoalsData` recharge ensuite la liste mémoire.

4. Delete (Supprimer)
   - UI : action Delete depuis `GoalDetailsPage` -> confirmation -> `GoalsData.deleteGoal(id)`.
   - `GoalDbService.deleteGoal(id)` exécute DELETE WHERE id = ?.
   - `GoalsData` recharge la liste mémoire.

5. Add contribution (Flux spécial)
   - UI : `AddContributionDialog` construit un `GoalTransaction` et appelle `GoalsData.addContribution(goalId, tx)`.
   - `GoalDbService.addContribution(goalId, tx)` : lit la ligne existante, décode le JSON `data`, ajoute la transaction à la liste `contributions`, incrémente `current` du goal, crée un nouvel objet `Goal` via `copyWith()` et appelle `updateGoal(updated)` pour persister.

Points techniques & choix d'implémentation
-----------------------------------------
- Stockage JSON dans une colonne `data` : simplifie sérialisation complète du modèle (incluant listes de milestones et contributions). Les colonnes séparées (title, target, current, ...) existe aussi pour faciliter les tris/requêtes simples.
- Upsert via `ConflictAlgorithm.replace` dans `insertGoal` : permet d'utiliser `insert` pour créer ou remplacer un goal existant.
- GoalApiService est un mock : utile pour remplacer par un serveur réel plus tard. L'architecture sépare logique locale (GoalDbService) et API (GoalApiService) pour faciliter ce remplacement.
- ExchangeRateService utilise plusieurs providers en fallback pour améliorer robustesse quand un fournisseur est indisponible.
- `HttpHelper.allowBadCerts` existe pour debug local (ne pas activer en production).

Fichiers importants (résumé rapide)
-----------------------------------
- lib/models/goal_model.dart — modèle et utilitaires (progress, daysRemaining...).
- lib/models/goals_data.dart — store mémoire + façade CRUD utilisée par l'UI.
- lib/services/goal_db_service.dart — implémentation SQLite (CRUD complet + addContribution).
- lib/services/goal_api_service.dart — API mock (simule latence réseau).
- lib/services/exchange_rate_service.dart — appels vers: exchangerate.host, frankfurter.app, open.er-api.com.
- lib/services/goal_export_service.dart — export CSV/XLSX/PDF & partage.
- lib/components/FinancialGoals/* et lib/pages/* — UI (dialogs, cards, pages).

Où est stockée la base de données ?
---------------------------------
- `GoalDbService._initDB` utilise `getDatabasesPath()` (fourni par `sqflite`) pour obtenir le dossier databases de l'application et crée `goals.db`.
- Sur Android réel : `/data/data/<applicationId>/databases/goals.db`.
- Sur iOS/desktop/emulateur les chemins diffèrent, mais `sqflite` gère l'emplacement.

APIs externes (liste et exemples d'URL)
--------------------------------------
- exchangerate.host
  - Example URL : https://api.exchangerate.host/latest?base=TND&symbols=USD
  - Usage : premier provider interrogé par `ExchangeRateService.fetchRate()`.

- frankfurter.app
  - Example URL : https://api.frankfurter.app/latest?from=TND&to=USD
  - Usage : fallback si exchangerate.host échoue.

- open.er-api.com
  - Example URL : https://open.er-api.com/v6/latest/TND
  - Usage : fallback supplémentaire.

- Goals API
  - Pas d'API distante actuellement ; `GoalApiService` est un mock local (simulé). Si vous avez un backend réel, remplacez les implémentations de `GoalApiService` par des requêtes HTTP réelles et coordonnez avec `GoalDbService` pour la synchronisation.

API de citations (Quote API)
----------------------------
Le projet inclut également un petit service pour afficher des citations inspirantes : `lib/services/quote_api_service.dart`.

- Fournisseurs interrogés (dans l'ordre) :
  1. `https://api.quotable.io/random` (utilisé pour `fetchRandomQuote` et `fetchThemedQuote` via tags)
  2. `https://zenquotes.io/api/random` ou `https://zenquotes.io/api/quotes` (utilisé comme fallback ou pour rechercher localement)
  3. `https://type.fit/api/quotes` (liste publique utilisée comme fallback aléatoire)

- Méthodes principales :
  - `QuoteApiService.fetchRandomQuote({http.Client? client})`
    - Tente chaque provider séquentiellement jusqu'à obtenir une réponse valide.
    - En cas de succès, la citation est mise en cache dans `SharedPreferences` sous la clé `quote_api_last`.
    - Si tous les providers échouent, le service renvoie la citation mise en cache (si disponible), sinon une citation de secours statique.
  - `QuoteApiService.fetchThemedQuote(String theme, {http.Client? client})`
    - Tente d'utiliser `quotable` avec le paramètre `tags` pour récupérer une citation en rapport avec `theme`.
    - Si le provider ne supporte pas la recherche thématique, essaye de filtrer les listes (ex: `zenquotes` ou `type.fit`) pour trouver un élément contenant le mot-clé.
    - Si aucune citation thématique n'est trouvée, retourne une citation choisie aléatoirement depuis une liste « curated » (ex: thèmes `goals`, `motivation`, `saving`).

- Caching & résilience :
  - Utilise `SharedPreferences` pour stocker la dernière citation réussie (`quote_api_last`).
  - Pas de TTL actuellement : le cache n'expire pas automatiquement.
  - `QuoteApiService` accepte un `http.Client` optionnel (via `HttpHelper.createClient()`), ce qui facilite le test et le debug (ex: `HttpHelper.allowBadCerts`).
  - Les erreurs des providers sont capturées et ignorées (on passe au provider suivant) ; en dernier recours on renvoie un texte de fallback.

- Intégration UI : `QuoteBanner` (`lib/components/FinancialGoals/quote_banner.dart`)
  - Au `initState` : le widget initialise un `Future<String>` via `QuoteApiService.fetchThemedQuote('goals')`.
  - Affichage : `FutureBuilder` montre un `CircularProgressIndicator` pendant le chargement, puis la citation (ou un texte par défaut si aucune donnée).
  - Rafraîchissement : un bouton `IconButton` appelle `_refresh()` qui remplace la `Future` par un nouvel appel à `fetchThemedQuote`, déclenchant un rebuild et une nouvelle requête.
  - Développement : un `onLongPress` ouvre une page de dev (`ApiDevPage`) si elle existe (accès masqué pour debug).

- Points à connaître / limites actuelles :
  - Pas d'authentification ni de clés API : les providers publics sont utilisés sans clé. Vérifiez les quotas et politiques d'utilisation (peuvent limiter la fréquence). 
  - Aucune gestion de TTL ou de timestamp du cache : la citation stockée est réutilisée sans vérification d'ancienneté.
  - Gestion d'erreur minimaliste : les exceptions sont silencieuses et n'informent pas explicitement l'utilisateur lorsque toutes les sources échouent (on retourne un fallback discret).

- Suggestions d'améliorations :
  - Ajouter un TTL pour la citation en cache (stocker également l'horodatage dans `SharedPreferences`) et utiliser le cache si l'appel réseau est impossible ou si la dernière citation est récente.
  - Mettre en place une stratégie de backoff / retry limitée (ex: exponential backoff) pour atténuer les erreurs transitoires.
  - Afficher une source ou attribution (ex: « via quotable.io ») lorsqu'une citation vient d'un provider externe.
  - Implémenter un mécanisme de quota/cooldown côté UI pour éviter des appels répétés (ex: désactiver refresh pendant X secondes).
  - Fournir des tests unitaires en moquant `http.Client` (package `http_mock_adapter` est disponible dans `pubspec.yaml`) et en mockant `SharedPreferences` lors des tests.
  - Pour production, considérer un proxy serveur qui centralise les appels aux providers (gestion de clés, caching centralisé, respect des quotas).

Hugging Face — reformulation SMART (Text Generation)
---------------------------------------------------
Objectif : utiliser la génération de texte (Hugging Face Inference API) pour reformuler un objectif libre en un « Objectif SMART » en français.

Pourquoi ?
- Aide l'utilisateur à transformer des phrases vagues (ex : "Je veux mieux gérer mon temps") en objectifs actionnables (ex : "Objectif SMART : Réduire le temps d'écran à 2h/jour d'ici 1 mois").

Options d'API
- Hugging Face Inference API (https://huggingface.co/inference-api) : simple à appeler via REST. Gratuit avec quota limité, ou payant selon usage.
- Modèles recommandés (bons compromis coût/qualité) :
  - `google/flan-t5-small` (léger, instruction-following)
  - `facebook/opt-125m` (optionnel)
  - `bigscience/bloomz-560m` (plus gros, meilleure génération en français)

Design & prompt
- Utiliser un prompt francophone explicite : demander une seule phrase qui commence par "Objectif SMART :".
- Exemple de prompt (fourni par la librairie Dart) :

  Réécris l'objectif suivant pour qu'il soit SMART (Spécifique, Mesurable, Atteignable, Réaliste, Temporellement défini).

  Entrée: "Je veux mieux gérer mon temps"

  Sortie attendue: Une seule phrase commençant par "Objectif SMART :" suivie de l'objectif reformulé en français (court et précis).

Sécurité & stockage des clefs
- Stockez la clé API Hugging Face dans un stockage sécurisé (`flutter_secure_storage`) et ne la commitez jamais.
- Pour un POC local, `SharedPreferences` peut suffire mais ce n'est pas recommandé en production.

Étapes d'intégration UI (haute-niveau)
1. Ajouter un champ/option "Reformuler en SMART" dans `AddGoalDialog` ou `GoalDetailsPage` (bouton adjacent au champ Title/Description).
2. À l'appui, appeler `HuggingFaceService.generateSmartGoal(input)` (mettre un petit loader UI pendant l'appel).
3. Afficher le texte généré dans un champ éditable (l'utilisateur peut accepter ou ajuster) puis sauvegarder le Goal.
4. Gérer les erreurs (quota, réseau) : afficher message et laisser l'utilisateur saisir manuellement.

Exemple d'utilisation Dart

```dart
import 'package:your_app/services/huggingface_service.dart';

final hf = HuggingFaceService();
hf.setApiKey(savedHfApiKey);
final smart = await hf.generateSmartGoal('Je veux mieux gérer mon temps');
print(smart); // Objectif SMART : ...
```

UI integration notes
- Afficher un `CircularProgressIndicator` pendant la génération.
- Limiter les appels (ex: 1 appel par pression, débounce le champ) pour respecter les quotas.
- Permettre de choisir le modèle (option avancée) et de régler `temperature` / `max_new_tokens` pour affiner la sortie.

Exemples de prompt & post-processing
- Toujours valider que la sortie commence par "Objectif SMART :" ; sinon, préfixer ou demander une nouvelle génération.
- Nettoyer les retours (trim, remplacer les retours à la ligne par espace, s'assurer qu'il s'agit d'une seule phrase).

Coûts et limites
- L'API Hugging Face Inference peut être gratuite avec un quota limité ; surveillez le dashboard Hugging Face.
- Pour usage intensif, héberger un modèle en self-hosting ou utiliser un modèle plus petit pour réduire les coûts.

Prochaines étapes (implémentation automatique)
- Je peux :
  1) ajouter un bouton "Reformuler en SMART" dans `AddGoalDialog` qui appelle `HuggingFaceService` et remplit automatiquement le champ Title/Description ;
  2) remplacer `SharedPreferences` par `flutter_secure_storage` pour stocker la clé HF ;
  3) écrire des tests unitaires pour `HuggingFaceService` en moquant `http.Client`.

Test & débogage
----------------
- Exécuter l'application :
  - flutter pub get
  - flutter run
- Vous pouvez tester le module Goals : ajouter, éditer, supprimer, ajouter contributions, exporter CSV/Excel/PDF et partager.
- Exchange Rate : le widget `ConvertedAmount` appelle `ExchangeRateService` via `FutureBuilder`; si aucune API répond ou si la devise cible = source, seul le montant base s'affiche.

Bonnes pratiques / améliorations possibles
----------------------------------------
- Synchronisation réseau : implémenter un vrai backend et une logique de sync (optimistic updates, gestion de conflits).
- Tests unitaires : enrichir `test/goals_data_test.dart` pour couvrir insert/update/delete/addContribution.
- Migrations DB : ajouter versionning et `onUpgrade` si le schéma évolue.
- Sécurité : ne pas activer `HttpHelper.allowBadCerts` en prod.
- Pagination / recherche : ajouter des colonnes indexées si le nombre de goals devient grand.

Résumé rapide (pour un développeur)
----------------------------------
- Les goals sont persistés en SQLite via `GoalDbService` et exposés en mémoire via `GoalsData.goals`.
- Le flux CRUD est : UI -> GoalsData -> GoalDbService -> SQLite.
- Aucun service distant n'est requis pour la gestion des goals (GoalApiService est un mock). Seuls les taux de change proviennent d'APIs publiques (exchangerate.host, frankfurter.app, open.er-api.com) via `ExchangeRateService`.
- L'export utilise `excel`, `pdf` et `share_plus` pour créer et partager des fichiers depuis le dossier documents de l'application.

Si vous souhaitez
- une version README en anglais,
- l'instrumentation pour synchronisation avec un backend REST (ex : routes recommandées et payloads JSON),
- ou des tests unitaires supplémentaires pour `GoalDbService`/`GoalsData`,
je peux les ajouter et les implémenter directement dans le projet.

Fin du document.
