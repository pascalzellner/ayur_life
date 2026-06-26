# Module BLE — Ayur Life (Phase 1, incrément 1)

Chaîne d'acquisition qui **dérisque le reste du projet** : connexion au capteur cardiaque
BLE (Polar H10, Cardiosport…), décodage FC + RR, et écran de debug affichant FC, RR, RMSSD
et taux d'artefacts **en direct**.

> Cible **Android**. Le BLE ne fonctionne **pas** sur émulateur : il faut un téléphone
> physique (mode développeur + débogage USB). Flutter ≥ 3.27 (utilise `Color.withValues`).

## 1. Création du projet (si pas déjà fait)

```bash
flutter create --org com.ayurai --project-name ayur_life \
  --platforms android --empty \
  --description "Ayur Life — suivi physiologique (ayur-ai.com)" ayur_life
cd ayur_life
```

## 2. Dépendances

```bash
flutter pub add flutter_blue_plus flutter_riverpod permission_handler
```

## 3. Copier les fichiers

Déposer en respectant l'arborescence (écraser `lib/main.dart` généré) :

```
lib/
  main.dart
  data/ble/heart_rate_parser.dart
  data/ble/ble_heart_rate_repository.dart
  data/ble/ble_providers.dart
  domain/hrv/live_hrv_accumulator.dart
  features/debug/ble_debug_screen.dart
test/
  heart_rate_parser_test.dart
  live_hrv_accumulator_test.dart
android/app/src/main/AndroidManifest.xml   # remplace celui généré (permissions BLE)
```

## 4. Réglage Android

Dans `android/app/build.gradle.kts` (ou `.gradle`), fixer le minimum requis par le BLE :

```kotlin
defaultConfig {
    minSdk = 21      // requis pour le Bluetooth Low Energy
    // applicationId reste com.ayurai.ayur_life
}
```

## 5. Lancer

```bash
flutter devices         # vérifier que le téléphone est listé
flutter run             # sur l'appareil physique
flutter test            # exécuter les tests unitaires (parser + accumulateur)
flutter analyze         # doit rester vert
```

## 6. Tester avec le capteur

1. Humidifier les électrodes de la ceinture (sinon RR bruités au démarrage).
2. Activer le Bluetooth, lancer l'app, **Scanner les capteurs**.
3. Toucher le capteur (Polar H10 / Cardiosport) dans la liste → connexion.
4. Vérifier : FC cohérente, RR autour de 700–1100 ms au repos, **taux d'artefacts < 5 %**.

## Notes capteurs

- **Polar H10 / Cardiosport** exposent le Heart Rate Service standard (`0x180D`), RR de
  qualité. Le H10 a un service propriétaire (PMD, ECG brut) **non utilisé** ici.
- Un seul lien BLE actif à la fois côté app. Le H10 supporte 2 connexions BLE + ANT+.

## Périmètre de cet incrément

✅ Scan, connexion, reconnexion automatique, décodage trame, RMSSD glissant, taux d'artefacts, UI debug.
▶️ **Suite** : service de premier plan (`flutter_foreground_task`, type `connectedDevice`) pour
l'acquisition longue (mode D), puis persistance `drift`, puis détection de seuils (mode B).

Voir `CLAUDE.md` / `AyurLife.md` à la racine pour le contexte complet du projet.
