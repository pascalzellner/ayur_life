import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:ayur_life/domain/hrv/poincare.dart';

void main() {
  // Série de référence calculée à la main.
  // RR = [800, 810, 800, 790, 805, 795] ms
  // mean = 800 ; variance = 250/6 → SDNN = sqrt(250/6) ≈ 6.455
  // diffs = [10, −10, −10, 15, −10] → RMSSD = sqrt(625/5) = sqrt(125) ≈ 11.180
  // SD1 = RMSSD/√2 ≈ 7.906
  // SD2 = sqrt(2·SDNN²  SD1²) = sqrt(500/6 − 125/2) ≈ 4.564
  const rr = [800.0, 810.0, 800.0, 790.0, 805.0, 795.0];

  group('computeSdnn', () {
    test('série de référence → ≈ 6.455', () {
      expect(computeSdnn(rr), closeTo(math.sqrt(250 / 6), 0.001));
    });

    test('liste vide → NaN', () {
      expect(computeSdnn([]).isNaN, isTrue);
    });

    test('un seul élément → NaN (besoin ≥ 2)', () {
      expect(computeSdnn([800.0]).isNaN, isTrue);
    });

    test('deux éléments identiques → 0.0', () {
      expect(computeSdnn([800.0, 800.0]), closeTo(0.0, 1e-9));
    });
  });

  group('computeSd1', () {
    test('série de référence → ≈ 7.906', () {
      // RMSSD = sqrt(125)
      const rmssd = 11.180339887498949;
      expect(computeSd1(rmssd), closeTo(rmssd / math.sqrt(2), 0.001));
    });

    test('rmssd NaN → NaN', () {
      expect(computeSd1(double.nan).isNaN, isTrue);
    });

    test('rmssd = 0 → SD1 = 0', () {
      expect(computeSd1(0.0), closeTo(0.0, 1e-9));
    });
  });

  group('computeSd2', () {
    test('série de référence → ≈ 4.564', () {
      final sdnn = computeSdnn(rr);
      final sd1 = computeSd1(math.sqrt(125));
      expect(computeSd2(sdnn, sd1), closeTo(math.sqrt(500 / 6 - 125 / 2), 0.01));
    });

    test('sdnn NaN → NaN', () {
      expect(computeSd2(double.nan, 7.9).isNaN, isTrue);
    });

    test('sd1 NaN → NaN', () {
      expect(computeSd2(6.4, double.nan).isNaN, isTrue);
    });

    test('sq ≤ 0 (sd1 > sdnn·√2) → NaN protecteur', () {
      // Cas dégénéré : RMSSD très élevé vs SDNN très faible (artefact numérique)
      expect(computeSd2(1.0, 100.0).isNaN, isTrue);
    });

    test('SD1² + SD2² = 2·SDNN² (identité Poincaré)', () {
      // Identité algébrique exacte : SD1² + SD2² = RMSSD²/2 + (2·SDNN² − RMSSD²/2) = 2·SDNN².
      final sdnn = computeSdnn(rr);
      final sd1 = computeSd1(math.sqrt(125));
      final sd2 = computeSd2(sdnn, sd1);
      expect(sd1 * sd1 + sd2 * sd2, closeTo(2 * sdnn * sdnn, 0.001));
    });
  });
}
