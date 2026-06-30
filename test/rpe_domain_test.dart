import 'package:flutter_test/flutter_test.dart';
import 'package:ayur_life/domain/load/rpe.dart';

void main() {
  // ── fosterLoad ────────────────────────────────────────────────────────────
  group('fosterLoad', () {
    test('RPE 6 × 30 min = 180 UA', () {
      expect(fosterLoad(6, const Duration(minutes: 30)), 180.0);
    });

    test('RPE 0 × n\'importe quelle durée = 0 UA', () {
      expect(fosterLoad(0, const Duration(hours: 2)), 0.0);
    });

    test('RPE 10 × 60 min = 600 UA', () {
      expect(fosterLoad(10, const Duration(hours: 1)), 600.0);
    });

    test('durée nulle ou négative → 0 UA', () {
      expect(fosterLoad(7, Duration.zero), 0.0);
      expect(fosterLoad(7, const Duration(seconds: 30)), 0.0); // < 1 min
    });

    test('seules les minutes entières comptent (pas les secondes résiduelles)', () {
      // 90 min 45 s → 90 minutes entières
      expect(
        fosterLoad(4, const Duration(minutes: 90, seconds: 45)),
        closeTo(360.0, 0.001),
      );
    });

    test('RPE hors plage lance ArgumentError', () {
      expect(() => fosterLoad(-1, const Duration(minutes: 10)),
          throwsA(isA<ArgumentError>()));
      expect(() => fosterLoad(11, const Duration(minutes: 10)),
          throwsA(isA<ArgumentError>()));
    });
  });

  // ── clamperRpe (CR10 0–10) ────────────────────────────────────────────────
  group('clamperRpe', () {
    test('valeur null → null', () => expect(clamperRpe(null), isNull));
    test('valeur dans la plage → inchangée', () {
      expect(clamperRpe(0), 0);
      expect(clamperRpe(5), 5);
      expect(clamperRpe(10), 10);
    });
    test('valeur en dessous du min → 0', () => expect(clamperRpe(-3), 0));
    test('valeur au-dessus du max → 10', () => expect(clamperRpe(15), 10));
  });

  // ── clamperRpeComp (−2..+2) ───────────────────────────────────────────────
  group('clamperRpeComp', () {
    test('valeur null → null', () => expect(clamperRpeComp(null), isNull));
    test('valeurs dans la plage → inchangées', () {
      expect(clamperRpeComp(-2), -2);
      expect(clamperRpeComp(0), 0);
      expect(clamperRpeComp(2), 2);
    });
    test('en dessous de −2 → −2', () => expect(clamperRpeComp(-5), -2));
    test('au-dessus de +2 → +2', () => expect(clamperRpeComp(4), 2));
  });

  // ── validateRpe ───────────────────────────────────────────────────────────
  group('validateRpe', () {
    test('valeurs valides passent sans erreur', () {
      for (final v in [0, 3, 7, 10]) {
        expect(validateRpe(v), v);
      }
    });
    test('valeur −1 lance ArgumentError', () {
      expect(() => validateRpe(-1), throwsA(isA<ArgumentError>()));
    });
    test('valeur 11 lance ArgumentError', () {
      expect(() => validateRpe(11), throwsA(isA<ArgumentError>()));
    });
  });

  // ── validateRpeComp ───────────────────────────────────────────────────────
  group('validateRpeComp', () {
    test('valeurs valides passent sans erreur', () {
      for (final v in [-2, -1, 0, 1, 2]) {
        expect(validateRpeComp(v), v);
      }
    });
    test('valeur −3 lance ArgumentError', () {
      expect(() => validateRpeComp(-3), throwsA(isA<ArgumentError>()));
    });
    test('valeur 3 lance ArgumentError', () {
      expect(() => validateRpeComp(3), throwsA(isA<ArgumentError>()));
    });
  });

  // ── constantes ────────────────────────────────────────────────────────────
  group('constantes de plage', () {
    test('bornes CR10 correctes', () {
      expect(rpeMin, 0);
      expect(rpeMax, 10);
    });
    test('bornes comparaison correctes', () {
      expect(rpeCompMin, -2);
      expect(rpeCompMax, 2);
    });
  });
}
