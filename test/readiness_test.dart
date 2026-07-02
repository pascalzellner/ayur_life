import 'package:flutter_test/flutter_test.dart';

import 'package:ayur_life/domain/state/readiness.dart';

void main() {
  // ── BaselineStats ────────────────────────────────────────────────────────
  group('computeBaseline', () {
    test('liste vide → null', () {
      expect(computeBaseline([]), isNull);
    });

    test('< 7 valeurs → not established', () {
      final b = computeBaseline([40.0, 38.0, 42.0, 39.0, 41.0, 43.0]);
      expect(b, isNotNull);
      expect(b!.established, isFalse);
      expect(b.count, 6);
    });

    test('= 7 valeurs → established', () {
      final b = computeBaseline([40.0, 38.0, 42.0, 39.0, 41.0, 43.0, 44.0]);
      expect(b!.established, isTrue);
      expect(b.count, 7);
    });

    test('> 7 valeurs → established', () {
      final vals = List.filled(10, 45.0);
      final b = computeBaseline(vals);
      expect(b!.established, isTrue);
      expect(b.count, 10);
    });

    test('mean correct sur valeurs connues', () {
      final b = computeBaseline([40.0, 50.0, 60.0]);
      expect(b!.mean, closeTo(50.0, 0.001));
    });

    test('lowerThreshold = mean − 2·σ', () {
      // σ = 0 → seuil = mean
      final b = computeBaseline(List.filled(7, 42.0));
      expect(b!.lowerThreshold, closeTo(42.0, 0.001));
    });

    test('upperThreshold = mean + 2·σ', () {
      final b = computeBaseline(List.filled(7, 42.0));
      expect(b!.upperThreshold, closeTo(42.0, 0.001));
    });

    test('stdDev non nulle sur valeurs variables', () {
      final b = computeBaseline([38.0, 40.0, 42.0, 44.0, 46.0, 48.0, 50.0]);
      expect(b!.stdDev, greaterThan(0));
    });
  });

  // ── computeHooperScore ──────────────────────────────────────────────────
  group('computeHooperScore', () {
    test('4 × 1 = 4 (minimum)', () {
      expect(computeHooperScore(fatigue: 1, stress: 1, doms: 1, sleep: 1), 4);
    });

    test('4 × 7 = 28 (maximum)', () {
      expect(computeHooperScore(fatigue: 7, stress: 7, doms: 7, sleep: 7), 28);
    });

    test('valeurs mixtes', () {
      expect(computeHooperScore(fatigue: 4, stress: 3, doms: 5, sleep: 2), 14);
    });
  });

  // ── classifyReadiness ────────────────────────────────────────────────────
  group('classifyReadiness — baseline insuffisante', () {
    test('baseline null → indicative', () {
      final c = classifyReadiness(
        rmssdToday: 38.0,
        rmssdBaseline: null,
        hooperScoreToday: 10,
        hooperBaseline: null,
      );
      expect(c, ReadinessClassification.indicative);
    });

    test('baseline présente mais non établie (< 7) → indicative', () {
      final rBase = computeBaseline([40.0, 42.0, 38.0, 41.0, 39.0, 43.0]); // 6
      final hBase = computeBaseline([10.0, 11.0, 12.0, 10.0, 11.0, 12.0]); // 6
      expect(rBase!.established, isFalse);
      final c = classifyReadiness(
        rmssdToday: 38.0,
        rmssdBaseline: rBase,
        hooperScoreToday: 10,
        hooperBaseline: hBase,
      );
      expect(c, ReadinessClassification.indicative);
    });
  });

  group('classifyReadiness — 4 branches (baseline établie)', () {
    // Baseline RMSSD : mean=45, σ=0 → lower=45  (seuil déviation: < 45)
    // Baseline Hooper : mean=12, σ=0 → upper=12  (seuil élevé: > 12)
    final rBase = computeBaseline(List.filled(7, 45.0))!;
    final hBase = computeBaseline(List.filled(7, 12.0))!;

    test('RMSSD ok + Hooper ok → noFatigue', () {
      final c = classifyReadiness(
        rmssdToday: 46.0, // >= lowerThreshold (45)
        rmssdBaseline: rBase,
        hooperScoreToday: 12.0, // <= upperThreshold (12)
        hooperBaseline: hBase,
      );
      expect(c, ReadinessClassification.noFatigue);
    });

    test('RMSSD dévié + Hooper élevé → markedFatigue', () {
      final c = classifyReadiness(
        rmssdToday: 30.0, // < 45 → dévié
        rmssdBaseline: rBase,
        hooperScoreToday: 20.0, // > 12 → élevé
        hooperBaseline: hBase,
      );
      expect(c, ReadinessClassification.markedFatigue);
    });

    test('RMSSD dévié + Hooper ok → mixedHrvDown', () {
      final c = classifyReadiness(
        rmssdToday: 30.0, // < 45 → dévié
        rmssdBaseline: rBase,
        hooperScoreToday: 10.0, // ≤ 12 → ok
        hooperBaseline: hBase,
      );
      expect(c, ReadinessClassification.mixedHrvDown);
    });

    test('RMSSD ok + Hooper élevé → mixedHooperUp', () {
      final c = classifyReadiness(
        rmssdToday: 50.0, // > 45 → ok
        rmssdBaseline: rBase,
        hooperScoreToday: 20.0, // > 12 → élevé
        hooperBaseline: hBase,
      );
      expect(c, ReadinessClassification.mixedHooperUp);
    });

    test('RMSSD exactement au seuil → non dévié (noFatigue si Hooper ok)', () {
      // rmssdToday == lowerThreshold : pas dévié (condition stricte <)
      final c = classifyReadiness(
        rmssdToday: 45.0, // == lowerThreshold → pas dévié
        rmssdBaseline: rBase,
        hooperScoreToday: 12.0, // == upperThreshold → pas élevé (> strictement)
        hooperBaseline: hBase,
      );
      expect(c, ReadinessClassification.noFatigue);
    });
  });

  // ── readinessMessage ────────────────────────────────────────────────────
  group('readinessMessage', () {
    test('chaque classification retourne un message non vide', () {
      for (final c in ReadinessClassification.values) {
        final msg = readinessMessage(c);
        expect(msg, isNotEmpty);
      }
    });

    test('les messages ne contiennent pas de vocabulaire clinique interdit', () {
      const forbiddenWords = ['burn-out', 'burnout', 'diagnos', 'traitement'];
      for (final c in ReadinessClassification.values) {
        final msg = readinessMessage(c).toLowerCase();
        for (final word in forbiddenWords) {
          expect(msg, isNot(contains(word)),
              reason: 'Message "$msg" contient "$word" (vocabulaire clinique interdit)');
        }
      }
    });
  });
}
