import 'package:flutter_test/flutter_test.dart';
import 'package:ayur_life/domain/hrv/live_hrv_accumulator.dart';

void main() {
  group('LiveHrvAccumulator', () {
    test('RMSSD sur variations < 5 % (aucun artefact)', () {
      final acc = LiveHrvAccumulator();
      // Écarts faibles : aucun ne dépasse 5 % de la médiane locale.
      acc.addRr(800);
      acc.addRr(820);
      acc.addRr(810);
      // diffs successives : +20, -10 → RMSSD = sqrt((400+100)/2) ≈ 15,81
      expect(acc.rmssd, closeTo(15.81, 0.1));
      expect(acc.artifactRatio, 0.0);
      expect(acc.beatsInWindow, 3);
    });

    test('Un RR physiologiquement impossible (< 300 ms) est toujours artefact', () {
      // Étage 1 : plausibilité absolue, pas d'amorçage requis.
      final acc = LiveHrvAccumulator();
      final flagged = acc.addRr(200); // 200 ms < 300 ms → impossible
      expect(flagged, isTrue);
      expect(acc.artifactRatio, greaterThan(0));
    });

    test('Un RR aberrant (> 20 %) est marqué artefact après amorçage (8 battements)', () {
      // Étage 2 : filtre médian — actif seulement après 8 battements propres.
      final acc = LiveHrvAccumulator();
      for (var i = 0; i < 8; i++) {
        acc.addRr(800); // 8 battements propres → amorçage terminé
      }
      final flagged = acc.addRr(1200); // +50 % vs médiane 800 ms → artefact
      expect(flagged, isTrue);
      expect(acc.artifactRatio, greaterThan(0));
      // Le RMSSD porte sur les 8 RR valides identiques → 0.
      expect(acc.rmssd, closeTo(0.0, 0.001));
    });

    test('FC moyenne déduite des RR', () {
      final acc = LiveHrvAccumulator();
      acc.addRr(1000); // 1000 ms → 60 bpm
      acc.addRr(1000);
      expect(acc.meanHr, closeTo(60.0, 0.001));
    });

    test('reset remet les compteurs à zéro', () {
      final acc = LiveHrvAccumulator();
      acc.addRr(800);
      acc.addRr(810);
      acc.reset();
      expect(acc.totalReceived, 0);
      expect(acc.beatsInWindow, 0);
      expect(acc.rmssd, isNaN);
    });
  });
}
