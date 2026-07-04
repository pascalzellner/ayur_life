import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:ayur_life/domain/load/trimp.dart';

void main() {
  // Profil de référence partagé
  const hrRest = 60;
  const hrMax = 200;

  group('computeTrimpBanisterSegment', () {
    test('homme (k=0,64) — valeur de référence à 50% FCR', () {
      // ratio = (130−60)/(200−60) = 70/140 = 0.5
      // TRIMP = 1.0 × 0.5 × 0.64 × e^(1.92×0.5)
      const ratio = 0.5;
      final expected = 1.0 * ratio * 0.64 * math.exp(1.92 * ratio);
      expect(
        computeTrimpBanisterSegment(
          durationMin: 1.0,
          hrSegment: 130,
          hrRest: hrRest,
          hrMax: hrMax,
          sex: 'M',
        ),
        closeTo(expected, 1e-9),
      );
    });

    test('femme (k=1,67) — valeur de référence à 50% FCR', () {
      const ratio = 0.5;
      final expected = 1.0 * ratio * 1.67 * math.exp(1.92 * ratio);
      expect(
        computeTrimpBanisterSegment(
          durationMin: 1.0,
          hrSegment: 130,
          hrRest: hrRest,
          hrMax: hrMax,
          sex: 'F',
        ),
        closeTo(expected, 1e-9),
      );
    });

    test('"autre" utilise le coeff masculin (0,64)', () {
      expect(
        computeTrimpBanisterSegment(
          durationMin: 1.0, hrSegment: 130,
          hrRest: hrRest, hrMax: hrMax, sex: 'autre',
        ),
        computeTrimpBanisterSegment(
          durationMin: 1.0, hrSegment: 130,
          hrRest: hrRest, hrMax: hrMax, sex: 'M',
        ),
      );
    });

    test('FC = FCrepos → TRIMP = 0 (ratio ≤ 0)', () {
      expect(
        computeTrimpBanisterSegment(
          durationMin: 1.0, hrSegment: 60,
          hrRest: 60, hrMax: 200, sex: 'M',
        ),
        0.0,
      );
    });

    test('FC < FCrepos → TRIMP = 0 (ratio négatif)', () {
      expect(
        computeTrimpBanisterSegment(
          durationMin: 1.0, hrSegment: 50,
          hrRest: 60, hrMax: 200, sex: 'M',
        ),
        0.0,
      );
    });

    test('FC = FCmax → TRIMP maximal du segment', () {
      // ratio = 1.0
      final expected = 1.0 * 1.0 * 0.64 * math.exp(1.92);
      expect(
        computeTrimpBanisterSegment(
          durationMin: 1.0, hrSegment: 200,
          hrRest: hrRest, hrMax: hrMax, sex: 'M',
        ),
        closeTo(expected, 1e-9),
      );
    });

    test('durée nulle → TRIMP = 0', () {
      expect(
        computeTrimpBanisterSegment(
          durationMin: 0.0, hrSegment: 150,
          hrRest: hrRest, hrMax: hrMax, sex: 'M',
        ),
        0.0,
      );
    });

    test('FCmax ≤ FCrepos (données invalides) → TRIMP = 0', () {
      expect(
        computeTrimpBanisterSegment(
          durationMin: 1.0, hrSegment: 150,
          hrRest: 100, hrMax: 80, sex: 'M',
        ),
        0.0,
      );
    });

    test('durée proportionnelle : 2 min = 2× 1 min à même FC', () {
      final t1 = computeTrimpBanisterSegment(
        durationMin: 1.0, hrSegment: 140,
        hrRest: hrRest, hrMax: hrMax, sex: 'M',
      );
      final t2 = computeTrimpBanisterSegment(
        durationMin: 2.0, hrSegment: 140,
        hrRest: hrRest, hrMax: hrMax, sex: 'M',
      );
      expect(t2, closeTo(2 * t1, 1e-9));
    });
  });

  group('computeTrimpBanisterFromRr', () {
    // Construit une liste de samples RR synthétiques pour un HR donné.
    // Chaque battement est espacé de rrMs, tMs clamped dans [startMs, startMs+durationMs-1]
    // pour éviter qu'un arrondi FP place un beat dans la minute suivante.
    List<({int tMs, double rr, bool gap})> beats(
      double hr, {
      required int startMs,
      required int durationMs,
    }) {
      final rrMs = 60000.0 / hr;
      final endMs = startMs + durationMs;
      final result = <({int tMs, double rr, bool gap})>[];
      var t = startMs.toDouble();
      while (t < endMs) {
        final tMsVal = t.round().clamp(startMs, endMs - 1);
        result.add((tMs: tMsVal, rr: rrMs, gap: false));
        t += rrMs;
      }
      return result;
    }

    test('session vide → trimp=0, couverture=0', () {
      final result = computeTrimpBanisterFromRr(
        samples: [],
        hrRest: hrRest, hrMax: hrMax, sex: 'M',
        sessionDurationMs: 60000,
      );
      expect(result.trimpTotal, 0.0);
      expect(result.dataCoverageRatio, 0.0);
    });

    test('sessionDurationMs=0 → trimp=0, couverture=0', () {
      final result = computeTrimpBanisterFromRr(
        samples: [(tMs: 1000, rr: 800, gap: false)],
        hrRest: hrRest, hrMax: hrMax, sex: 'M',
        sessionDurationMs: 0,
      );
      expect(result.trimpTotal, 0.0);
      expect(result.dataCoverageRatio, 0.0);
    });

    test('1 minute à 130 bpm → TRIMP ≈ segment unitaire', () {
      final samples = beats(130, startMs: 0, durationMs: 60000);
      final result = computeTrimpBanisterFromRr(
        samples: samples,
        hrRest: hrRest, hrMax: hrMax, sex: 'M',
        sessionDurationMs: 60000,
      );
      final expected = computeTrimpBanisterSegment(
        durationMin: 1.0, hrSegment: 130,
        hrRest: hrRest, hrMax: hrMax, sex: 'M',
      );
      // Tolérance plus large car HR = 60000/meanRR ≈ 130 (arrondi des entiers)
      expect(result.trimpTotal, closeTo(expected, 0.01));
      expect(result.dataCoverageRatio, closeTo(1.0, 0.01));
    });

    test(
        'sommation par segments > TRIMP naïf sur FC moyenne '
        '(amplification exponentielle des pics)', () {
      // Min 1 : HR=80 (effort faible), min 2 : HR=160 (effort élevé)
      // FC moyenne = 120. Le TRIMP par segments doit être > TRIMP naïf.
      final min1 = beats(80, startMs: 0, durationMs: 60000);
      final min2 = beats(160, startMs: 60000, durationMs: 60000);
      final samples = [...min1, ...min2];

      final result = computeTrimpBanisterFromRr(
        samples: samples,
        hrRest: hrRest, hrMax: hrMax, sex: 'M',
        sessionDurationMs: 120000,
      );

      // TRIMP naïf (2 min à FC moyenne 120 bpm)
      final naive = computeTrimpBanisterSegment(
        durationMin: 2.0, hrSegment: 120,
        hrRest: hrRest, hrMax: hrMax, sex: 'M',
      );

      // Valeur attendue par segments (calculée depuis la formule)
      final r1 = (80 - hrRest) / (hrMax - hrRest);
      final r2 = (160 - hrRest) / (hrMax - hrRest);
      final expectedSeg = 0.64 * (r1 * math.exp(1.92 * r1) +
          r2 * math.exp(1.92 * r2));

      expect(result.trimpTotal, closeTo(expectedSeg, 0.05));
      expect(result.trimpTotal, greaterThan(naive),
          reason: 'Les pics intenses doivent amplifier le TRIMP vs la moyenne');
    });

    test('segments gap exclus du calcul', () {
      // 2 minutes valides + 1 minute de gap entre les deux
      final min1 = beats(130, startMs: 0, durationMs: 60000);
      // Minute 1 (60000–119999) = gap
      final gapRow = (tMs: 60000, rr: 0.0, gap: true);
      final min3 = beats(130, startMs: 120000, durationMs: 60000);

      final result = computeTrimpBanisterFromRr(
        samples: [...min1, gapRow, ...min3],
        hrRest: hrRest, hrMax: hrMax, sex: 'M',
        sessionDurationMs: 180000, // 3 minutes total
      );

      // 2 minutes avec données sur 3 → couverture ~0,67
      expect(result.dataCoverageRatio, closeTo(2.0 / 3.0, 0.05));

      // TRIMP = 2 segments (les 2 minutes valides)
      final segRef = computeTrimpBanisterSegment(
        durationMin: 1.0, hrSegment: 130,
        hrRest: hrRest, hrMax: hrMax, sex: 'M',
      );
      expect(result.trimpTotal, closeTo(2 * segRef, 0.05));
    });

    test('couverture complète : 5 min de données sur 5 min → ratio = 1.0', () {
      final samples = beats(120, startMs: 0, durationMs: 300000);
      final result = computeTrimpBanisterFromRr(
        samples: samples,
        hrRest: hrRest, hrMax: hrMax, sex: 'M',
        sessionDurationMs: 300000,
      );
      expect(result.dataCoverageRatio, closeTo(1.0, 0.01));
    });

    test('couverture partielle : 3 min sur 6 min → ratio ≈ 0.5', () {
      // Données uniquement dans les 3 premières minutes
      final samples = beats(120, startMs: 0, durationMs: 180000);
      final result = computeTrimpBanisterFromRr(
        samples: samples,
        hrRest: hrRest, hrMax: hrMax, sex: 'M',
        sessionDurationMs: 360000, // 6 min
      );
      expect(result.dataCoverageRatio, closeTo(0.5, 0.01));
    });

    test('rr=0 dans les données (ligne corrompue) ignorée', () {
      final samples = [
        (tMs: 1000, rr: 0.0, gap: false),  // rr=0 → ignoré
        (tMs: 2000, rr: 800.0, gap: false),
      ];
      final result = computeTrimpBanisterFromRr(
        samples: samples,
        hrRest: hrRest, hrMax: hrMax, sex: 'M',
        sessionDurationMs: 60000,
      );
      // Doit calculer normalement avec le rr=800 valide
      expect(result.trimpTotal, greaterThan(0));
    });
  });

  group('computeTrimpBanisterFromHr', () {
    test('session vide → trimp=0, couverture=0', () {
      final result = computeTrimpBanisterFromHr(
        samples: [],
        hrRest: hrRest, hrMax: hrMax, sex: 'M',
        sessionDurationMs: 60000,
      );
      expect(result.trimpTotal, 0.0);
      expect(result.dataCoverageRatio, 0.0);
    });

    test('sessionDurationMs=0 → trimp=0, couverture=0', () {
      final result = computeTrimpBanisterFromHr(
        samples: [(tMs: 1000, hr: 130)],
        hrRest: hrRest, hrMax: hrMax, sex: 'M',
        sessionDurationMs: 0,
      );
      expect(result.trimpTotal, 0.0);
      expect(result.dataCoverageRatio, 0.0);
    });

    test('1 minute à 130 bpm → TRIMP ≈ segment unitaire', () {
      // Plusieurs trames BLE à 130 bpm dans la première minute.
      final samples = List.generate(
        10,
        (i) => (tMs: i * 6000, hr: 130), // toutes dans minute 0
      );
      final result = computeTrimpBanisterFromHr(
        samples: samples,
        hrRest: hrRest, hrMax: hrMax, sex: 'M',
        sessionDurationMs: 60000,
      );
      final expected = computeTrimpBanisterSegment(
        durationMin: 1.0, hrSegment: 130,
        hrRest: hrRest, hrMax: hrMax, sex: 'M',
      );
      expect(result.trimpTotal, closeTo(expected, 1e-9));
      expect(result.dataCoverageRatio, closeTo(1.0, 0.01));
    });

    test('hr=0 ignoré', () {
      final samples = [
        (tMs: 0, hr: 0),    // invalide → ignoré
        (tMs: 1000, hr: 130),
      ];
      final result = computeTrimpBanisterFromHr(
        samples: samples,
        hrRest: hrRest, hrMax: hrMax, sex: 'M',
        sessionDurationMs: 60000,
      );
      expect(result.trimpTotal, greaterThan(0));
    });

    test('gap BLE > 1 minute → minute exclue, couverture < 100%', () {
      // Trame dans minute 0 uniquement ; minutes 1+ = pas de données.
      final samples = [(tMs: 5000, hr: 130)];
      final result = computeTrimpBanisterFromHr(
        samples: samples,
        hrRest: hrRest, hrMax: hrMax, sex: 'M',
        sessionDurationMs: 180000, // 3 minutes
      );
      // 1 minute avec données sur 3 → couverture ≈ 0.33
      expect(result.dataCoverageRatio, closeTo(1.0 / 3.0, 0.01));
    });

    test('couverture complète : données sur toutes les minutes → ratio = 1.0', () {
      // Une trame par minute sur 5 minutes.
      final samples = List.generate(5, (i) => (tMs: i * 60000 + 1000, hr: 120));
      final result = computeTrimpBanisterFromHr(
        samples: samples,
        hrRest: hrRest, hrMax: hrMax, sex: 'M',
        sessionDurationMs: 300000,
      );
      expect(result.dataCoverageRatio, closeTo(1.0, 0.01));
    });

    // Test comparatif : pic FC avec RR corrompus → FromHr > 0, FromRr = 0.
    // Simule une situation de mouvement intense : la trame BLE porte une FC
    // élevée mais aucun RR valide (tous artefacts rejetés ou absents).
    test('pic FC sans RR → FromHr capte la charge, FromRr = 0', () {
      // Données HR : 1 trame à 160 bpm dans la première minute.
      final hrSamples = [(tMs: 5000, hr: 160)];

      // Données RR correspondantes : vides (RR non émis pendant le mouvement).
      final rrSamples = <({int tMs, double rr, bool gap})>[];

      final trimpFromHr = computeTrimpBanisterFromHr(
        samples: hrSamples,
        hrRest: hrRest, hrMax: hrMax, sex: 'M',
        sessionDurationMs: 60000,
      );
      final trimpFromRr = computeTrimpBanisterFromRr(
        samples: rrSamples,
        hrRest: hrRest, hrMax: hrMax, sex: 'M',
        sessionDurationMs: 60000,
      );

      expect(trimpFromHr.trimpTotal, greaterThan(0),
          reason: 'La FC brute capte le pic même sans RR');
      expect(trimpFromRr.trimpTotal, 0.0,
          reason: 'Sans RR valide, computeFromRr ne peut pas calculer de TRIMP');
    });
  });
}
