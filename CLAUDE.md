# Ayur Life — Contexte projet (Claude Code)

> **Langue de travail : français** (code, commentaires, commits, échanges).
> Sources de vérité : `CDCF_AyurLife_Phase1.docx` (fonctionnel **v0.4**) et `CDCT_AyurLife_Phase1.docx`
> (technique v0.1). En cas de doute, **les cahiers priment**. Ce fichier fixe décisions, contraintes
> dures et apprentissages terrain ; il pointe vers les cahiers pour le détail.

---

## 1. Mission & positionnement

Aider un humain à **ne pas vivre au-dessus de ses moyens physiologiques** (capacité plafonnée
ATP/VO2max). But : santé physique **et psychique**, pas la performance. Garde-fou : rester sous le
1er seuil, borner la charge, détecter tôt la fatigue (HRV).

**RÈGLE DURE — bien-être, PAS dispositif médical.** Observe / informe / alerte de façon probabiliste ;
**ne diagnostique pas, ne traite pas**. Tout texte d'UI évite le vocabulaire de diagnostic
(« ta variabilité s'écarte de ta norme, sois prudent », jamais « burn-out »). Franchir = régime MDR.

## 2. Triptyque (ossature)

| Grandeur | Question | Indicateur |
|---|---|---|
| **Intensité** | Effort instantané soutenable ? | FC vs FC@SV1 (temps réel) |
| **Volume** | Trop accumulé ? | TRIMP cumulé (relatif, cf. PD-9) |
| **État** | Capacité du jour ? Dérive ? | HRV (RMSSD) vs ligne de base |

## 3. Décisions VERROUILLÉES (ne pas rouvrir)

- **Une seule source de vérité** : capteur BLE (FC + RR). Aucun autre capteur ne s'y substitue pour
  HRV/charge ; capteurs téléphone (mode D) = **contexte** seulement.
- **Local-first** (P1 : tout physiologique reste sur l'appareil). **Compte Supabase minimal** :
  identité + comm uniquement, **aucune** donnée physio/RPE au cloud en P1.
- **Gratuit = protecteur/autosuffisant** ; **payant = durabilité + horizon** (cloud) → P2. Le
  **longitudinal protecteur a vocation à rester gratuit** ; frontière fine = **principe ouvert** (cahier §13).
- **TRIMP** : Banister (FC, auto) défaut ; Edwards (zones) ; Foster (RPE) = charge subjective.
- **PD-9 — pas de seuil absolu de TRIMP** (n'existe pas : déjà normalisé par FC de réserve). Garde-fou
  Volume raisonne **en relatif individuel** (charge chronique, ACWR ~0,8–1,3 ; >1,5 alerte), jamais un plafond universel.
- **Rétention** : indicateurs + RPE = **longue** (≥ 6–12 mois) ; RR bruts = **courte** (purge récente).
- **Garde-fou Intensité** : FC instantanée (fiable même en mouvement) vs **FC de référence** = FC@SV1
  **mesurée** (mode B) sinon plafond **Karvonen** (~70 % FCR ; FCmax mesurée ou **Tanaka** 208−0,7×âge).
  La **provenance** (`measured_modeB`/`estimated_karvonen`) suit la valeur, l'UI l'affiche. Jamais traiter
  une estimation comme un seuil mesuré (PD-6).
- **Mode B** : **consentement 2 voies** (accord médical recommandé OU responsabilité assumée) + **PAR-Q+** ;
  journalisé/versionné (append-only).
- **Volet psychologique (RPE psy)** : montrer la donnée, inviter à la prudence, **JAMAIS d'étiquette
  clinique** (« stress majeur », « burn-out »… proscrits). Attend validation médicale avant toute UI.
- **Pas de GPS en P1** → zéro permission de localisation.
- **flutter_blue_plus** : `connect(license: License.commercial)` (entité lucrative). Gratuit sous le seuil
  d'employés (15 ou 50 — vérifier LICENSE) ; pas `License.nonprofit`.

## 4. Périmètre Phase 1

**Dans** : capteur BLE, triptyque, 4 modes, RPE (saisie + Foster), profil/calibration, stockage local +
rétention, compte Supabase (identité + comm).
**Hors** : GPS/traces/export .fit-.gpx → P2 ; sync cloud physio → P2 ; **modèles dérivés** (ACWR fin,
monotonie, strain, Fitness-Fatigue prédictif) → P2 (besoin d'historique) ; orthostatisme Schmitt → P2 ;
espace praticien → P3.

## 5. Les 4 modes (détail → CDCF §7)

- **A — Activité sportive** : coût séance, zones, TRIMP, garde-fou SV1, RPE physique à la clôture.
- **B — Test de seuils** : DFA α1 → HRVT1 (SV1) / HRVT2 (SV2). Consentement, cf. §3. Pas de RPE.
- **C — Readiness (matin)** : RMSSD vs baseline, readiness, alerte. Court (1′+2′ couché). RPE psy possible ici.
- **D — Journée pro** : enreg. long (≤ ~8 h) ceinture + capteurs téléphone. Pas de GPS. RPE physique +
  **RPE de comparaison** (−2..+2) les jours estimés sans ceinture (pondère le TRIMP estimé).

## 6. Architecture (couches → `domain`, feature-first)

```
lib/
  core/        # utilitaires, constantes, DI
  domain/      # PUR DART, testable, sans dépendance plateforme
    hrv/       #   rmssd, sdnn, poincare, dfa, frequency, live accumulator
    load/      #   trimp (banister, edwards), karvonen, tanaka, rpe (foster)
    state/     #   baseline, readiness, règles d'alerte
  data/
    ble/         # flutter_blue_plus : scan 0x180D, parsing 0x2A37, repo, providers
    foreground/  # service premier plan (connectedDevice)
    local/       # drift : tables, DAO, rétention
    sensors/     # pedometer, activité, baromètre (mode D)  — à venir
    account/     # supabase_flutter — à venir
  features/    # un dossier par mode + dashboard + debug
  main.dart
```

- **Domaine = pur Dart** → couvert par tests unitaires. **Calculs lourds** (DFA α1, FFT, spline) → `Isolate.run`.
- **État = Riverpod** sans codegen. Flux BLE/capteurs en `Stream`.

## 7. Stack technique

| Rôle | Paquet |
|---|---|
| BLE | `flutter_blue_plus` |
| Service premier plan | `flutter_foreground_task` (9.2.2) |
| FFT / spline | `fftea` / `equations` |
| **Base locale** | **`drift_flutter`** (PAS `drift`+`sqlite3_flutter_libs` — cf. §14) |
| Compte / État | `supabase_flutter` / `flutter_riverpod` |
| Capteurs mode D | `pedometer`, `sensors_plus` |
| Permissions / notifs | `permission_handler`, `flutter_local_notifications` |

**Maison** (domain, sans dépendance) : artefacts, RMSSD, SDNN, Poincaré, DFA α1, TRIMP, Karvonen, Foster.

## 8. Contraintes Android (dures)

- **Service premier plan** : `foregroundServiceType="connectedDevice"`. ⚠️ **JAMAIS `dataSync`**
  (timeout Android 15). `initCommunicationPort()` avant `runApp`.
- **Scan BLE sans localisation** : `BLUETOOTH_SCAN` + `neverForLocation` + `BLUETOOTH_CONNECT`. **Aucune** localisation.
- `POST_NOTIFICATIONS`, `ACTIVITY_RECOGNITION`, `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`. **minSdk = 31**
  (`build.gradle.kts` ; après changement : `fvm flutter clean`).
- **MIUI/Xiaomi** : exclusion optim. batterie + réglages manuels (démarrage auto, verrou récents).
  `autoRestart` : vérifier reprise BLE sans doublon (**point ouvert**).

## 9. Algorithmes HRV (référence ; détail → CDCF Annexe A)

Trame **0x2A37** : octet 0 = flags (bit0 FC 8/16b, bit3 énergie, bit4 RR) ; RR en **1/1024 s** → ms (`×1000/1024`).

| Indicateur | Fenêtre | | Indicateur | Fenêtre |
|---|---|---|---|---|
| RMSSD (réf.) | 1–2 min | | HF / LF | ≥2 min / 4–5 min |
| SDNN | ≥ 5 min | | Poincaré SD1/SD2 | ≥ 2 min |
| DFA α1 (boîtes 4–16) | ~200 batt. (2–3 min) | | | |

- **Seuils mode B** : HRVT1 α1 ≈ **0,75** (SD1 < 3 ms) ; HRVT2 α1 ≈ **0,50**. Fenêtres 2 min, recalcul ~5 s.
  Fréquentiel : spline 4 Hz puis FFT.
- **Filtrage RR — 2 étages, ne pas confondre** : **Live** (validé) = plausibilité **300–2000 ms** (rejet
  d'office) + écart médian **20 %** + amorçage **8 batt.** (`LiveHrvAccumulator`). **Offline M3** (à venir)
  = **5 %** sur signal stabilisé. Le 5 % n'est PAS pour le live (rejetterait la variabilité saine).

## 10. Modèle de données local (drift, schemaVersion 2)

6 tables, chacune porte **`userId`** (→ migration cloud P2 sans réécriture) :
`Sessions` (+ `rpePhysical` nullable) · `Indicators` (kind/value/at — **long**) · `RrSamples`
(PK `{sessionId,tMs}`, gap, FK cascade — **court**) · `ConsentLog` (**append-only**) ·
`Profile` (PK `userId`, upsert) · `DailyEntries` (PK `{userId,day}`, `rpePsychological` 0–10,
`rpeComparison` −2..+2).

- **Profile** (prêt garde-fou) : anthropo ; `hrRest`, `hrMax`+`hrMaxSource` ; `fcSv1`/`fcSv2` ;
  `thresholdProvenance` ; `aerobicCeiling` ; `baselineRmssd`+`baselineUpdatedAt`. = **photo courante,
  pas d'historique** → l'évolution se reconstruit depuis `Indicators` (historiser le profil = P2).
- **Foster non stocké** : fonction pure `fosterLoad(rpe, duree)` dans `domain/load/rpe.dart`.
- **Migrations additives uniquement** (jamais drop/deleteEverything) ; préserver les données.

## 11. Conventions

- Métier **en français** ; `fvm dart format` ; `fvm flutter analyze` **vert**.
- Domaine = fonctions pures + tests (réf. Kubios, tolérance). Aucun calcul HRV sur signal non validé.
- UI : vocabulaire non médical (§1). Charte : teal `#1B9AAA`, orange `#EE8B2C`.

## 12. Commandes (TOUJOURS préfixer `fvm` — cf. §14)

```bash
fvm flutter pub get | run (appareil PHYSIQUE, pas d'émulateur BLE) | test | analyze
fvm dart run build_runner build --delete-conflicting-outputs   # drift (watch en dev)
```

## 13. État actuel

- ✅ **Inc. 1** acquisition BLE (Garmin, Polar H10) · ✅ **Inc. 2** service premier plan (30 min MIUI) ·
  ✅ **Inc. 3** persistance drift (5 tables, rétention, flush ~30 s, gap) · ✅ **Inc. 4** RPE + Foster
  (schemaVersion 2, migration additive, `DailyEntries`).
- ▶️ **Prochain** : garde-fou Intensité (FC vs FC@SV1/Karvonen, lit `Profile`). Puis mode B.
- Tests : **54 au vert**. Historique détaillé → log Git.

## 14. Apprentissages terrain & pièges

**Build (CRITIQUE)**
- **SDK épinglé `fvm` Flutter 3.35.7 / Dart 3.9.2.** Dart 3.10 active les *native-assets hooks* ; sur
  Windows le hook `objective_c` (via `permission_handler`/`path_provider`) **fige `build_runner`**.
  **TOUJOURS** `fvm flutter/dart ...`. VS Code : `dart.flutterSdkPath = .fvm/flutter_sdk`. Remonter en
  3.10+ quand dart-lang/sdk#62593 corrigé. (« dart build » ne marche pas — ne pas retenter.)
- **`drift_flutter`** (pas `drift`+`sqlite3_flutter_libs`) : évite le hook sqlite3, binaires Android
  précompilés. Tests : `NativeDatabase.memory()` via `drift/native.dart`, importer `drift/drift.dart`
  avec `hide isNull, isNotNull`.

**Capteur / mesure**
- **HRV fiable UNIQUEMENT au repos/immobile** : en mouvement artefacts ~50 % = **NORMAL** (bruit rejeté),
  pas un bug → c'est un indicateur de fiabilité. Mode D : **FC** pour charge/intensité, **HRV** réservée au
  calme. UI : dire « signal trop bruité » plutôt qu'un chiffre faux.
- **Capteurs** : Garmin & Polar H10 propres ; **Cardiosport instable** (RR < 300 ms) → liste de capteurs validés.
- **UUID 128 bits** : comparer en sous-chaîne (`180d`/`2a37`), pas égalité stricte.

**Divers**
- **Coupures BLE longue durée (mode D)** : **POINT OUVERT** (interpoler/marquer/exclure du TRIMP) ; d'ici
  là juste **marquer** (`gap=true`).
- **Compteurs** : `totalBeats` (cumul, monte → à montrer) vs `beatsInWindow` (fenêtre, oscille → ne pas exposer).
- **geolocator absent** : le `FlutterGeolocator` en logcat venait d'une autre app. « Zéro localisation » intacte.