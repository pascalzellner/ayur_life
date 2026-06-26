# Ayur Life — Contexte projet (pour Claude Code)

> Fiche d'embarquement. **Langue de travail : français** (code, commentaires, commits, échanges).
> Sources de vérité formelles : `CDCF_AyurLife_Phase1.docx` (fonctionnel, v0.3) et
> `CDCT_AyurLife_Phase1.docx` (technique, v0.1). En cas de doute, ces deux cahiers priment.

---

## 1. Mission

Aider un humain à **ne pas vivre durablement au-dessus de ses moyens physiologiques**.
La capacité d'action est plafonnée par la production d'ATP, conditionnée par la VO2max.
But : des humains en bonne santé (physique et psychique), pas des athlètes. L'app est un
**garde-fou** : rester sous le premier seuil d'effort, borner la charge accumulée, détecter
tôt la fatigue (souvent infra-clinique) via la HRV.

## 2. Positionnement réglementaire — RÈGLE DURE

Statut **bien-être, PAS dispositif médical**. L'app **observe, informe, alerte** de façon
probabiliste ; elle ne **diagnostique pas** et ne **traite pas**.
➡️ **Tout texte d'UI évite le vocabulaire médical de diagnostic.** Formuler en bien-être :
« ta variabilité s'écarte de ta norme, sois prudent », jamais « tu fais un burn-out ».
Franchir cette ligne ferait basculer sous le régime MDR.

## 3. Le triptyque (ossature de tout)

| Grandeur | Question | Indicateur | Nature |
|---|---|---|---|
| **Intensité** | Mon effort instantané est-il soutenable ? | FC vs FC@SV1 | temps réel |
| **Volume** | Ai-je trop accumulé ? | TRIMP cumulé | cumulé |
| **État** | Quelle capacité du jour ? Suis-je en dérive ? | HRV (RMSSD) vs ligne de base | longitudinal |

## 4. Périmètre Phase 1 (et hors périmètre)

**Dans la Phase 1** : capteur cardiaque BLE seul, triptyque, 4 modes de mesure, profil/calibration,
stockage local + rétention, compte Supabase (identité + communication uniquement).

**HORS Phase 1** (ne pas implémenter sans validation) :
- GPS, traces, export `.fit`/`.gpx` → Phase 2
- Synchronisation cloud des données physiologiques → Phase 2 (palier payant)
- Espace praticien (suivi multi-clients façon nolio.io) → Phase 3
- Profils orthostatiques complets de Schmitt → Phase 2

## 5. Décisions VERROUILLÉES (ne pas relancer le débat)

- **Une seule source de vérité** : capteur cardiaque BLE (FC + RR). Aucun autre capteur ne
  s'y substitue pour la HRV et la charge. Les capteurs du téléphone (mode D) sont du **contexte**.
- **Local-first** : en Phase 1, toutes les données physiologiques restent sur l'appareil.
- **Compte Supabase obligatoire mais minimal** : identité + communication. **Aucune** donnée
  physiologique dans le cloud en Phase 1.
- **Gratuit = protecteur et autosuffisant** (SV1, TRIMP, alerte HRV de sécurité, baseline).
  **Payant = durabilité + horizon temporel** (cloud, historique illimité, longitudinal) → Phase 2.
- **TRIMP** : Banister (basé FC, automatique) = référence vie quotidienne ; Edwards = présentation
  par zones ; **Foster (session-RPE)** = optionnel, séances sportives volontaires seulement.
- **Rétention** : indicateurs par session = **rétention longue** (≥ 6–12 mois, cible à chiffrer) ;
  séries RR brutes = **rétention courte** (purge au-delà d'une fenêtre récente).
- **Mode B (test de seuils)** : encadré par un **consentement éclairé à deux voies** — (a) accord/
  responsabilité médicale (recommandé) OU (b) acceptation explicite de responsabilité — précédé
  d'un **PAR-Q+** de triage. Consentement **journalisé et versionné** (table append-only).
- **Repli sans test** : zones par **Karvonen** (FCR = FCmax − FCrepos), FCmax estimée par **Tanaka**
  (208 − 0,7 × âge), plafond aérobie estimé conservateur ≈ 70 % FCR. Toujours étiqueter « estimé ».
- **Pas de GPS en Phase 1** → aucune permission de localisation, donc pas d'examen Play Store.

## 6. Les 4 modes de mesure

- **Mode A — Activité sportive** (court/terrain) : coût d'une séance, zones, TRIMP, garde-fou SV1.
- **Mode B — Test de seuils incrémental** : DFA α1 → HRVT1 (SV1) / HRVT2 (SV2). Voir consentement §5.
- **Mode C — Fatigue / Readiness (matin)** : RMSSD du matin vs baseline, readiness, alerte sécurité.
  Mesure courte (1′ stabilisation + 2′ calcul, couché). Orthostatisme (5′+5′) en option avancée.
- **Mode D — Journée professionnelle type** : enregistrement long (≤ ~8 h) AVEC ceinture, + capteurs
  téléphone (pas, actif/sédentaire, baromètre). **Pas de GPS.** Apprend une signature FC↔métier.

## 7. Architecture du code

Couches (dépendances dirigées vers `domain`), feature-first :

```
lib/
  core/            # utilitaires, constantes, erreurs, DI
  domain/          # PUR DART, testable, sans dépendance plateforme
    hrv/           #   rmssd, sdnn, poincare, dfa, frequency, live accumulator
    load/          #   trimp (banister, edwards), karvonen, tanaka
    state/         #   baseline, readiness, règles d'alerte
  data/
    ble/           # flutter_blue_plus : scan 0x180D, parsing 0x2A37, repo, providers
    acquisition/   # foreground service, buffer, gap-marking  (à venir)
    sensors/       # pedometer, activity, baromètre (mode D)   (à venir)
    local/         # drift : tables, DAO, rétention, export CSV (à venir)
    account/       # supabase_flutter : auth, messagerie, RLS   (à venir)
  features/        # un dossier par mode + dashboard + debug
  main.dart
```

Règles :
- **Le domaine est pur Dart** (aucun import Flutter/plateforme) → c'est lui qu'on couvre par tests.
- **Calculs lourds hors du thread UI** : DFA α1 glissante, FFT, interpolation spline → `Isolate.run`.
- **État avec Riverpod** (sans codegen pour l'instant : `Provider`, `StreamProvider`,
  `NotifierProvider`). Les flux BLE/capteurs sont exposés en `Stream`.

## 8. Stack technique (versions à épingler au `pub add`)

| Domaine | Paquet |
|---|---|
| BLE | `flutter_blue_plus` |
| Service premier plan | `flutter_foreground_task` |
| FFT | `fftea` |
| Spline cubique | `equations` (`SplineInterpolation`) |
| Base locale | `drift` + `sqlite3_flutter_libs` |
| Compte | `supabase_flutter` |
| État | `flutter_riverpod` |
| Capteurs mode D | `pedometer`, `sensors_plus` (baromètre) |
| Permissions | `permission_handler` |
| Notifications | `flutter_local_notifications` |

Briques **maison** (domain, sans dépendance) : correcteur d'artefacts, RMSSD, SDNN, Poincaré,
DFA α1, TRIMP, Karvonen.
- **flutter_blue_plus** : licence FlutterBluePlus. Appel `device.connect(license: License.commercial)`
  (entité à but lucratif Ayur-AI). GRATUIT sous le seuil d'employés de la version installée
  (15 ou 50 selon version — à vérifier dans le LICENSE du package). Pas de redevance récurrente ;
  licence commerciale = paiement unique si le seuil est franchi. Alternative BSD/`bluetooth_low_energy`
  possible si les termes évoluent. → Ne PAS déclarer `License.nonprofit` (statut lucratif).

## 9. Contraintes Android — IMPORTANT

- **Service de premier plan** : pour l'acquisition longue (mode D), `foregroundServiceType="connectedDevice"`
  (permission `FOREGROUND_SERVICE_CONNECTED_DEVICE`).
  ⚠️ **NE PAS utiliser `dataSync`** : Android 15 lui impose un timeout, incompatible avec 8 h.
- **Scan BLE sans localisation** : `BLUETOOTH_SCAN` avec `android:usesPermissionFlags="neverForLocation"`,
  + `BLUETOOTH_CONNECT`. → évite `ACCESS_FINE_LOCATION`.
- **Aucune permission de localisation** en Phase 1 (pas de GPS).
- `POST_NOTIFICATIONS` (Android 13+) pour la notification persistante du service.
- `ACTIVITY_RECOGNITION` pour le podomètre (mode D).
- `startForeground()` doit être appelé < 10 s. `minSdkVersion >= 21` pour le BLE.
- **minSdk = 31** (Android 12) : choisi pour s'aligner sur les permissions BLE modernes
  (BLUETOOTH_SCAN + neverForLocation) et le « zéro localisation ». En dessous d'API 31,
  l'OS exigerait la permission de localisation pour le scan BLE — exclu par principe.
  Réglé dans android/app/build.gradle.kts (defaultConfig). Après changement : flutter clean.

## 10. Algorithmes HRV de référence

Décodage trame **0x2A37** : octet 0 = flags (bit0 format FC 8/16 bits, bit3 énergie présente,
bit4 RR présents) ; RR en **unité 1/1024 s** → ms via `× 1000 / 1024`.

| Indicateur | Fenêtre RR |
|---|---|
| RMSSD (référence fatigue) | 1–2 min |
| SDNN | ≥ 5 min |
| Moyenne RR | 1–5 min |
| HF (0,15–0,40 Hz) | ≥ 2 min |
| LF (0,04–0,15 Hz), LF/HF | 4–5 min |
| Poincaré SD1/SD2 | ≥ 2 min |
| DFA α1 (boîtes 4–16 battements) | ~200 battements (2–3 min) |

- **Prétraitement** : correction d'artefacts (filtre **5 %** vs médiane/moyenne locale) AVANT tout calcul.
- **Fréquentiel** : rééchantillonnage **spline cubique à 4 Hz** (signal équidistant) puis FFT.
- **Seuils (mode B)** : HRVT1 (SV1) à **α1 ≈ 0,75** (confirmation : stabilisation SD1 < 3 ms) ;
  HRVT2 (SV2) à **α1 ≈ 0,50**. Fenêtres glissantes **2 min**, recalcul toutes les **~5 s**.
- **Karvonen** : `FC_cible = FCrepos + (FCmax − FCrepos) × %FCR`. **Tanaka** : `FCmax ≈ 208 − 0,7 × âge`.
  Plafond aérobie estimé (proxy SV1) ≈ 70 % FCR.

## 11. Modèle de données local (drift)

Tables clés : `Sessions` (userId, mode A/B/C/D, startedAt, endedAt, quality),
`Indicators` (sessionId, kind, value — **rétention longue**),
`RrSamples` (sessionId, tMs, rr, gap — **rétention courte**),
`ConsentLog` (**append-only** : userId, route `medical|self_responsibility`, acceptedAt,
appVersion, consentVersion), `Profile`/`Calibration` (anthropométrie, FCrepos, FCmax,
FC@SV1/SV2 **avec provenance** `mesurée|estimée`, zones, baseline RMSSD).
Chaque enregistrement porte `userId` → migration cloud Phase 2 sans réécriture.

## 12. Conventions de code

- Commentaires et identifiants métier **en français** ; respecter `dart format`.
- `flutter analyze` doit rester vert ; viser des warnings à zéro.
- Domaine = fonctions pures + tests unitaires (comparaison à une référence type Kubios, tolérance).
- Pas de calcul HRV sur signal non validé par la correction d'artefacts (mémoriser le taux).
- UI : vocabulaire non médical (cf. §2). Charte : teal `#1B9AAA`, orange `#EE8B2C`.

## 13. Commandes

```bash
flutter pub get
flutter run                 # sur appareil physique (le BLE NE marche PAS sur émulateur)
flutter test                # tests unitaires (priorité : domain/hrv)
flutter analyze
dart format .
# quand drift sera ajouté :
dart run build_runner build --delete-conflicting-outputs
```

## 14. État actuel

✅ **Module d'acquisition BLE VALIDÉ SUR APPAREIL RÉEL** (incrément 1 terminé) :
- Scan, connexion stable, décodage trame 0x2A37, conversion RR (1/1024 s → ms), filtre de
  plausibilité physiologique, RMSSD glissant temps réel — testés avec succès sur Garmin et Polar H10.
- `flutter analyze` vert, `flutter test` : 11 tests passent (parser + accumulateur HRV).
- Mesure réelle confirmée : RR regroupés ~800 ms, RMSSD crédible et stable, taux d'artefacts maîtrisé
  après application du filtre de plausibilité.
- Fichiers : data/ble/ (parser, repository, providers), domain/hrv/live_hrv_accumulator.dart,
  features/debug/ble_debug_screen.dart.

▶️ **Prochain incrément** : SERVICE DE PREMIER PLAN (`flutter_foreground_task`, type `connectedDevice`)
pour transformer le module de debug en acquisition LONGUE et DURABLE (écran éteint, plusieurs heures,
résistant à Doze). Première vraie brique du mode D (journée professionnelle).
Puis : persistance drift, puis détection de seuils (mode B).

## 15. Pièges connus

- **Émulateur = pas de BLE.** Toujours tester sur le téléphone physique (mode développeur + USB).
- **Polar H10 / Cardiosport** : exposent le Heart Rate Service standard (0x180D), RR de qualité.
  Le H10 a un service propriétaire (PMD, ECG brut) **non utilisé** ici — on reste sur le HRS standard.
  Humidifier la ceinture avant mesure, sinon taux d'artefacts élevé au démarrage.
- **UUID 128 bits** : comparer les UUID découverts de façon tolérante (sous-chaîne `180d`/`2a37`),
  pas par égalité stricte de `Guid`.
- **Doze / surcouches constructeurs** : peuvent tuer le service long → tester sur vraie journée,
  proposer l'exclusion d'optimisation batterie.
- **Coupures BLE sur longue durée (mode D)** : POINT OUVERT (interpoler / marquer / exclure du TRIMP).
  À trancher avant de coder le mode D — d'ici là, juste **marquer** les trous (`gap=true`).
-**flutter_blue_plus — licence FlutterBluePlus** : connect(license: License.commercial) choisi (entité à but lucratif Ayur-AI). Gratuit sous le seuil d'employés de la version ; vérifier une éventuelle obligation d'enregistrement gratuit dans la section « Commercial Terms » du LICENSE. Alternative BSD/bluetooth_low_energy si les termes évoluent. 
- **Qualité capteur très variable (validé sur le terrain)** : le Cardiosport émet des RR
  FRAGMENTÉS/PARASITES (valeurs < 300 ms, FC pourtant correcte) quand le contact peau est
  imparfait → taux d'artefacts catastrophique. Le Garmin et le Polar H10 donnent un signal propre.
  À terme : recommander une LISTE DE CAPTEURS VALIDÉS (Garmin, Polar H10) plutôt que « n'importe
  quelle ceinture ». Illustre concrètement le principe « une seule source de vérité, capteur de qualité ».
- **Filtre de plausibilité physiologique INDISPENSABLE** : tout RR < 300 ms ou > 2000 ms est
  physiologiquement impossible → rejeté d'office, AVANT toute comparaison à la médiane. Implémenté
  dans LiveHrvAccumulator (étage 1). Sans lui, les capteurs médiocres polluent tout l'affichage.
- **Filtre médian live assoupli** : seuil à 20 % (pas 5 %) + amorçage à 8 battements avant de juger.
  Le 5 % strict est réservé au futur correcteur M3 hors-ligne (sur signal stabilisé). Un filtre trop
  serré rejette la variabilité saine (arythmie sinusale respiratoire) qu'on cherche justement à mesurer.
- **geolocator n'est PAS dans le projet** : le `FlutterGeolocator` vu dans les logADB venait d'une
  AUTRE app du téléphone (PID distinct). Promesse « zéro localisation » intacte.
