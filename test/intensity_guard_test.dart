import 'package:flutter_test/flutter_test.dart';

import 'package:ayur_life/domain/load/calibration.dart';
import 'package:ayur_life/domain/load/intensity_guard.dart';

void main() {
  // ── checkSessionStart ───────────────────────────────────────────────────────

  group('checkSessionStart', () {
    test('âge manquant seul → non autorisé', () {
      final c = checkSessionStart(age: null, hrRest: 55);
      expect(c.allowed, isFalse);
      expect(c.ageMissing, isTrue);
      expect(c.hrRestMissing, isFalse);
      expect(c.missingFields, contains('âge'));
    });

    test('FC repos manquante seule → non autorisé', () {
      final c = checkSessionStart(age: 35, hrRest: null);
      expect(c.allowed, isFalse);
      expect(c.hrRestMissing, isTrue);
      expect(c.ageMissing, isFalse);
      expect(c.missingFields, contains('FC de repos'));
    });

    test('les deux manquants → non autorisé, deux champs', () {
      final c = checkSessionStart(age: null, hrRest: null);
      expect(c.allowed, isFalse);
      expect(c.missingFields, hasLength(2));
    });

    test('âge + FC repos présents → autorisé', () {
      final c = checkSessionStart(age: 35, hrRest: 55);
      expect(c.allowed, isTrue);
      expect(c.missingFields, isEmpty);
    });
  });

  // ── computeIntensityRef ─────────────────────────────────────────────────────

  group('computeIntensityRef', () {
    test('fcSv1 mesurée mode B → provenance measuredSv1', () {
      final ref = computeIntensityRef(
        hrRest: 55,
        hrMax: 185,
        age: 35,
        fcSv1: 142,
        thresholdProvenance: ThresholdProvenance.measuredModeB.name,
      );
      expect(ref, isNotNull);
      expect(ref!.bpmRef, 142);
      expect(ref.provenance, IntensityRefProvenance.measuredSv1);
      expect(ref.label, 'FC@SV1 mesurée');
    });

    test('fcSv1 présente mais provenance estimatedKarvonen → repli Karvonen', () {
      // SV1 non issue d'un mode B → on ne l'utilise pas comme référence mesurée.
      final ref = computeIntensityRef(
        hrRest: 55,
        hrMax: 185,
        age: 35,
        fcSv1: 142,
        thresholdProvenance: ThresholdProvenance.estimatedKarvonen.name,
      );
      expect(ref, isNotNull);
      expect(ref!.provenance, IntensityRefProvenance.estimatedKarvonen);
      // Karvonen 70 % : 55 + 0.7 × (185 − 55) = 55 + 91 = 146
      expect(ref.bpmRef, 146);
    });

    test('repli Karvonen avec hrMax mesurée', () {
      final ref = computeIntensityRef(
        hrRest: 60,
        hrMax: 180,
        age: null,
        fcSv1: null,
        thresholdProvenance: null,
      );
      expect(ref, isNotNull);
      expect(ref!.provenance, IntensityRefProvenance.estimatedKarvonen);
      // 60 + 0.7 × 120 = 60 + 84 = 144
      expect(ref.bpmRef, 144);
    });

    test('repli Karvonen avec hrMax Tanaka (pas de hrMax mesurée)', () {
      // âge 40 → Tanaka 208 − 0,7 × 40 = 180
      final ref = computeIntensityRef(
        hrRest: 60,
        hrMax: null,
        age: 40,
        fcSv1: null,
        thresholdProvenance: null,
      );
      expect(ref, isNotNull);
      expect(ref!.provenance, IntensityRefProvenance.estimatedKarvonen);
      // 60 + 0.7 × (180 − 60) = 60 + 84 = 144
      expect(ref.bpmRef, 144);
    });

    test('hrRest manquant → null', () {
      final ref = computeIntensityRef(
        hrRest: null,
        hrMax: 185,
        age: 35,
        fcSv1: null,
        thresholdProvenance: null,
      );
      expect(ref, isNull);
    });

    test('hrRest manquant + hrMax manquant + pas d\'âge → null', () {
      final ref = computeIntensityRef(
        hrRest: null,
        hrMax: null,
        age: null,
        fcSv1: null,
        thresholdProvenance: null,
      );
      expect(ref, isNull);
    });
  });

  // ── Validation saisie manuelle ──────────────────────────────────────────────

  group('validation saisie manuelle', () {
    test('hrRest valide : bornes 35–100', () {
      expect(isHrRestManualValid(35), isTrue);
      expect(isHrRestManualValid(55), isTrue);
      expect(isHrRestManualValid(100), isTrue);
      expect(isHrRestManualValid(34), isFalse);
      expect(isHrRestManualValid(101), isFalse);
      // Cas terrain reproduit : 20 bpm était accepté alors qu'il doit être rejeté.
      expect(isHrRestManualValid(20), isFalse,
          reason: 'hrRest = 20 bpm est physiologiquement impossible (< 35)');
    });

    test('hrMax valide : bornes 120–220', () {
      expect(isHrMaxManualValid(120), isTrue);
      expect(isHrMaxManualValid(185), isTrue);
      expect(isHrMaxManualValid(220), isTrue);
      expect(isHrMaxManualValid(119), isFalse);
      expect(isHrMaxManualValid(221), isFalse);
    });
  });

  // ── OverrunTracker ──────────────────────────────────────────────────────────

  DateTime t(int secondsFromEpoch) =>
      DateTime.fromMillisecondsSinceEpoch(secondsFromEpoch * 1000, isUtc: true);

  group('OverrunTracker — mode A (premier seuil 10 s, répétition 30 s)', () {
    late OverrunTracker tracker;

    setUp(() {
      tracker = OverrunTracker(config: OverrunConfig.modeA, refBpm: 140);
    });

    test('pas d\'alerte sous la référence', () {
      for (var i = 0; i < 30; i++) {
        final e = tracker.add(130, t(i));
        expect(e, isNull, reason: 'aucune alerte à t=$i');
      }
      expect(tracker.isOver, isFalse);
      expect(tracker.continuousOverrunSeconds, 0);
    });

    test('alerte à 10 s de dépassement continu (première)', () {
      OverrunEvent? firstAlert;
      for (var i = 0; i <= 10; i++) {
        final e = tracker.add(150, t(i));
        if (e != null) firstAlert = e;
      }
      expect(firstAlert, isNotNull);
      expect(firstAlert!.isFirst, isTrue);
    });

    test('pas d\'alerte avant 10 s', () {
      for (var i = 0; i < 10; i++) {
        expect(tracker.add(150, t(i)), isNull,
            reason: 'pas d\'alerte avant le seuil t=$i');
      }
    });

    test('remise à zéro quand FC repasse sous la référence', () {
      // Dépasse 12 s → alerte première.
      for (var i = 0; i <= 12; i++) {
        tracker.add(150, t(i));
      }
      expect(tracker.isOver, isTrue);

      // Retour sous la référence.
      tracker.add(130, t(13));
      expect(tracker.isOver, isFalse);
      expect(tracker.continuousOverrunSeconds, 0);

      // Dépasse à nouveau — le compteur repart de zéro (pas d'alerte avant 10 s).
      for (var i = 14; i < 24; i++) {
        expect(tracker.add(150, t(i)), isNull);
      }
      // À t=24 → 10 s depuis t=14 → première alerte.
      final e = tracker.add(150, t(24));
      expect(e, isNotNull);
      expect(e!.isFirst, isTrue);
    });

    test('répétition d\'alerte toutes les 30 s', () {
      // Première alerte à t=10.
      for (var i = 0; i <= 10; i++) {
        tracker.add(150, t(i));
      }
      // Pas d'alerte avant 30 s supplémentaires.
      for (var i = 11; i < 40; i++) {
        expect(tracker.add(150, t(i)), isNull);
      }
      // À t=40 (10 + 30) → répétition.
      final e = tracker.add(150, t(40));
      expect(e, isNotNull);
      expect(e!.isFirst, isFalse);
    });

    test('totalOverSeconds et totalUnderSeconds s\'accumulent correctement', () {
      // 5 s sous la référence.
      for (var i = 0; i < 5; i++) {
        tracker.add(130, t(i));
      }
      // 15 s au-dessus.
      for (var i = 5; i < 20; i++) {
        tracker.add(150, t(i));
      }
      // Les temps sont en secondes (inter-sample ≈ 1 s).
      expect(tracker.totalUnderSeconds, greaterThanOrEqualTo(4));
      expect(tracker.totalOverSeconds, greaterThanOrEqualTo(14));
    });

    test('reset() remet tout à zéro', () {
      for (var i = 0; i <= 15; i++) {
        tracker.add(150, t(i));
      }
      tracker.reset();
      expect(tracker.isOver, isFalse);
      expect(tracker.continuousOverrunSeconds, 0);
      expect(tracker.totalOverSeconds, 0);
      expect(tracker.totalUnderSeconds, 0);
      expect(tracker.add(150, t(100)), isNull); // pas d'alerte immédiate
    });
  });

  group('OverrunTracker — mode D (premier seuil 60 s, répétition 60 s)', () {
    late OverrunTracker tracker;

    setUp(() {
      tracker = OverrunTracker(config: OverrunConfig.modeD, refBpm: 140);
    });

    test('pas d\'alerte avant 60 s', () {
      for (var i = 0; i < 60; i++) {
        expect(tracker.add(150, t(i)), isNull);
      }
    });

    test('première alerte à 60 s', () {
      OverrunEvent? event;
      for (var i = 0; i <= 60; i++) {
        event = tracker.add(150, t(i));
      }
      expect(event, isNotNull);
      expect(event!.isFirst, isTrue);
    });

    test('répétition à 60 s après première alerte', () {
      for (var i = 0; i <= 60; i++) {
        tracker.add(150, t(i));
      }
      for (var i = 61; i < 120; i++) {
        expect(tracker.add(150, t(i)), isNull);
      }
      final e = tracker.add(150, t(120));
      expect(e, isNotNull);
      expect(e!.isFirst, isFalse);
    });
  });
}
